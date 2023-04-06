using System.Xml.Serialization;
using GerarClasses.Entidade;

namespace GerarClasses
{
    public  class ClassIO
    {
        public ClassIO()
        {
            
        }

        public static string ObtenhaConteudoDeArquivoTexto(string pathArquivo)
        {
            StreamReader streamReader = new StreamReader(pathArquivo);
            string text = streamReader.ReadToEnd();
            streamReader.Close();
            return text;
        }


        public static List<CriacaoClasse> DeserializeObject(string sourceFolderPath)
        {
            if (Directory.Exists(sourceFolderPath))
            {
                DirectoryInfo dirSource = new DirectoryInfo(sourceFolderPath);
                var allXMLFiles = dirSource.GetFiles("*.xml", SearchOption.TopDirectoryOnly).ToList();

                List<CriacaoClasse> listAllEntries = new List<CriacaoClasse>();

                foreach (var nextFile in allXMLFiles)
                {
                    try
                    {
                        XmlSerializer serializer = new XmlSerializer(typeof(CriacaoClasse));
                        using (TextReader reader = new StringReader(System.IO.File.ReadAllText(nextFile.FullName)))
                        {
                            CriacaoClasse result = (CriacaoClasse)serializer.Deserialize(reader);
                            //var teste = serializer.Deserialize(reader);
                            listAllEntries.Add(result);
                        }
                    }
                    catch (Exception ex)
                    {

                    }
                }

                return listAllEntries;
            }
            return new List<CriacaoClasse>();
        }

        
    }
}
