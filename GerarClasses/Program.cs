// See https://aka.ms/new-console-template for more information
using GerarClasses;
using System.IO;


string path = "C:\\processar";

ProcessarDados pd = new ProcessarDados(path);
pd.CriarClassMapeamento();
pd.CriaContexto();




Console.ReadKey();
