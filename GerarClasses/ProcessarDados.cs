using GerarClasses.Entidade;

namespace GerarClasses
{
    public class ProcessarDados
    {
        public ProcessarDados(string caminhoBase)
        {
            CaminhoBase = caminhoBase;

            folder = CaminhoBase + "\\resultado";
            Directory.CreateDirectory(folder);

            conteudo = new List<string>();
            contextoMap = new List<string>();
            contextoClass = new List<string>();
            conteudo = new List<string>();
        }

        public string CaminhoBase { get; set; }
        public List<string> conteudo { get; set; }
        public  List<string> contextoMap { get; set; }
        public  List<string> contextoClass { get; set; }
        public  string folderPlus { get; set; }
        public  string folder { get; set; }


        public void CriarClassMapeamento()
        {
            Console.WriteLine("Iniciando processamento na pasta " + CaminhoBase);

            List<CriacaoClasse> itensProcessar = ClassIO.DeserializeObject(CaminhoBase);

            Console.WriteLine("Recuperado arquivo, será gerado um total de " + itensProcessar.FirstOrDefault().Itens.Count() + " arquivos");

            foreach (CriacaoClasse cria in itensProcessar)
            {
                foreach (Itens item in cria.Itens)
                {
                    if (item.Tipo == "Classe")
                    {
                        folderPlus = folder + "\\Classe";
                        contextoClass.Add("public DbSet<" + item.NomeArquivo + "> " + item.NomeArquivo + " { get; set; }");
                    }
                    else
                    {
                        folderPlus = folder + "\\Mapeamento";
                        contextoMap.Add("modelBuilder.ApplyConfiguration(new " + item.NomeArquivo + "());");
                    }
                    Console.WriteLine("Criando arquivo " + folderPlus + '\\' + item.NomeArquivo + '.' + item.ExtensaoArquivo);
                    conteudo.Clear();
                    string arquivo = Path.Combine(folderPlus, item.NomeArquivo + '.' + item.ExtensaoArquivo);
                    Directory.CreateDirectory(folderPlus);
                    File.Create(arquivo).Dispose();
                    conteudo.Add(item.ConteudoArquivo);
                    File.WriteAllLines(arquivo, conteudo);
                }
            }
        }

        public void CriaContexto()
        {
            if (contextoClass.Count > 0 || contextoMap.Count > 0)
            {
                conteudo.Clear();
                string arquivo = Path.Combine(folder, "ContextDefault.cs");
                Directory.CreateDirectory(folder);
                File.Create(arquivo).Dispose();
                conteudo.AddRange(contextoClass);
                conteudo.Add("");
                conteudo.AddRange(contextoMap);
                File.WriteAllLines(arquivo, conteudo);
            }

            Console.WriteLine("Geração concluida, consultar a pasta " + folder);
        }

        public void CriaHandler()
        { 
            
        }

    }
}

