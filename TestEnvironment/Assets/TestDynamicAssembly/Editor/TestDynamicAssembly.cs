using UnityEngine;
using System.Collections;
using UnityEditor;
using UnityEngine.UI;
using System;
using System.IO;
using System.Reflection;
using System.Reflection.Emit;

public static class TestDynamicAssembly
{
    [MenuItem("Tools/TestDynamicAssembly/Build", false, 105)]
    public static void Build()
    {
        // https://www.cnblogs.com/Leo_wl/p/5666364.html

        /*
         * public class Hello
         * {
         *      public static void SayHello()
         *      {
         *          Console.WriteLine("Hello, World");
         *          Console.ReadLine();
         *      }
         * }
         */

        string outputFolder = EditorUtility.OpenFolderPanel("choose output folder", "", "");
        if (string.IsNullOrEmpty(outputFolder))
            return;

        string moduleName = "Main.exe";

        var asmName = new AssemblyName("Test");
        var asmBuilder = AppDomain.CurrentDomain.DefineDynamicAssembly(asmName, AssemblyBuilderAccess.RunAndSave, outputFolder);
        var mdlBldr = asmBuilder.DefineDynamicModule("Main", moduleName);
        var typeBldr = mdlBldr.DefineType("Hello", TypeAttributes.Public);
        var methodBldr = typeBldr.DefineMethod(
            "SayHello",
            MethodAttributes.Public | MethodAttributes.Static,
            null,//return type               
            null//parameter type       
        );
        var il = methodBldr.GetILGenerator();//获取il生成器  
        il.Emit(OpCodes.Ldstr, "Hello, World");
        il.Emit(OpCodes.Call, typeof(Console).GetMethod("WriteLine", new Type[] { typeof(string) }));
        il.Emit(OpCodes.Call, typeof(Console).GetMethod("ReadLine"));
        il.Emit(OpCodes.Pop);//读入的值会被推送至evaluation stack，而本方法是没有返回值的，因此，需要将栈上的值抛弃    
        il.Emit(OpCodes.Ret);
        var t = typeBldr.CreateType();
        asmBuilder.SetEntryPoint(t.GetMethod("SayHello"));
        asmBuilder.Save(moduleName);
    }
}
