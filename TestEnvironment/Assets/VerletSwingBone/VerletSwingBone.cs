using UnityEngine;
using System.Collections.Generic;

public class VerletSwingBone : MonoBehaviour
{
    public class BoneNode
    {
        public Transform trans;

        // origin local rotation
        public Quaternion originLocalRotation;
        // origin length between self and child
        public float originLength;

        // origin radius for calulate collision
        public float originRadius;

        // prevous frame position
        public Vector3 prevPos;
        // current frame position
        public Vector3 curPos;
    }

    public Transform rootBone;

    // drag force 
    public float dragForce = 0.4f;
    // stiffness force 
    public float stiffnessForce = 0.1f;
    // bone space forward axis
    public Vector3 boneAxis = new Vector3(0.0f, 0.0f, -1.0f);

    // not important
    public WindZone windZone;

    // not important
    public SphereCollider sphereCollider;

    private List<BoneNode> nodes = new List<BoneNode>();

    private void Awake()
    {
        Transform trans = rootBone ? rootBone : this.transform;
        while (trans.childCount > 0)
        {
            Transform child = trans.GetChild(0);
            BoneNode node = new BoneNode();
            node.trans = trans;
            node.originLocalRotation = trans.localRotation;
            node.originLength = Vector3.Distance(trans.position, child.position);
            node.originRadius = trans.localScale.x * 0.5f;
            node.prevPos = child.position;
            node.curPos = child.position;
            nodes.Add(node);
            trans = child;
        }
    }

    public void LateUpdate()
    {
        foreach (var node in nodes)
        {
            // reset rotation
            node.trans.localRotation = node.originLocalRotation;

            Vector3 nodePos = node.trans.position;
            Quaternion nodeRotation = node.trans.rotation;

            /* base knowledge
             * F = m * a
             * F = a (if m == 1)
             * v = a * dt
             * d = v * dt
             * F = d / dt^2
             * 
             * caculate stiffness force
             * A---------------B
             * d(stiffness A<--B) = V(BA) * stiffness
             * V(BA) = nodeRotation(A) * boneAxis
             * d(stiffness A<--B) = nodeRotation(A) * boneAxis * stiffness
             * F(stiffness) = nodeRotation(A) * boneAxis * stiffness / dt^2
             * 
             * caculate drag force
             * A---------------B
             * d(drag A-->B) = V(AB) * drag
             * V(AB) = node.prevPos - node.curPos
             * d(drag A-->B) = (node.prevPos - node.curPos) * drag
             * F(drag) = (node.prevPos - node.curPos) * drag / dt^2
             */

            // dt^2
            float sqrDt = Time.deltaTime * Time.deltaTime;
            // caculate F(stiffness)
            Vector3 force = nodeRotation * boneAxis * stiffnessForce / sqrDt;
            // caculate F(drag)
            force += (node.prevPos - node.curPos) * dragForce / sqrDt;
            // add other force(like wind)
            if (windZone)
            {
                float noise = Mathf.PerlinNoise(Time.time * windZone.windTurbulence, 0f);
                noise = noise * 2f - 1f;
                force += windZone.transform.forward * windZone.windMain * noise / sqrDt;
            }

            /* https://en.wikipedia.org/wiki/Verlet_integration
             * https://www.zhihu.com/question/22531466
             * taylor:
             *      f(x) = f(a) + f'(a) * (x-a) + f''(a) * (x-a)^2 / 2 + f'''(a) * (x-a)^3 / 6
             *      
             *  set a = x-h:
             *      f(x) = f(x-h) + f'(x-h) * h + f''(x-h) * h^2 / 2 + f'''(x-h) * h^3 / 6
             *      f(x+h) = f(x) + f'(x) * h + f''(x) * h^2 / 2 + f'''(x) * h^3 / 6
             *      f(x-h) = f(x) - f'(x) * h + f''(x) * h^2 / 2 - f'''(x) * h^3 / 6
             *      
             *  special if f'''(x) == 0:
             *  A = f(x+h) = f(x) + f'(x) * h + f''(x) * h^2 / 2
             *  B = f(x-h) = f(x) - f'(x) * h + f''(x) * h^2 / 2
             *  
             * verlet:
             *      A - B ==> f(x+h) - f(x-h) = 2 * f'(x) * h 
             *  ==> f'(x) = (f(x+h) - f(x-h)) / (2*h)
             *  
             *      A + B ==> f(x+h) + f(x-h) = 2 * f(x) + f''(x) * h^2
             *  ==> f(x+h) = 2 * f(x) + f''(x) * h^2 - f(x-h) 
             *      
             * convert: f -> pos, h -> dt, x -> t, f''(x) ==> a(t)
             *      pos(t + dt) = 2 * pos(t) + a(t) * dt^2 - pos(t - dt)
            */
            Vector3 nextPos = 2 * node.curPos + force * sqrDt - node.prevPos;
            node.prevPos = node.curPos;
            // keep length
            node.curPos = ((nextPos - nodePos).normalized * node.originLength) + nodePos;

            if (sphereCollider)
            {
                Vector3 colliderPos = sphereCollider.transform.position;
                float radiusSum = sphereCollider.radius * sphereCollider.transform.localScale.x + node.originRadius;
                if (Vector3.Distance(node.curPos, colliderPos) < radiusSum)
                {
                    Vector3 normal = (node.curPos - colliderPos).normalized;
                    node.curPos = colliderPos + normal * radiusSum;
                    node.curPos = ((node.curPos - nodePos).normalized * node.originLength) + nodePos;
                }
            }

            // boneAxis transform from local to world
            Vector3 worldBoneAxis = node.trans.TransformDirection(boneAxis);
            Vector3 nodeDir = node.curPos - nodePos;
            // caculate worldBoneAxis transform to nodeDir rotation 
            Quaternion boneToDirRotation = Quaternion.FromToRotation(worldBoneAxis, nodeDir);
            node.trans.rotation = boneToDirRotation * node.trans.rotation;
        }
    }
}

