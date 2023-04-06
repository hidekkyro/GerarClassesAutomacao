/* 
 Licensed under the Apache License, Version 2.0

 http://www.apache.org/licenses/LICENSE-2.0
 */
using System;
using System.Xml.Serialization;
using System.Collections.Generic;

namespace GerarClasses.Entidade
{
    [XmlRoot(ElementName = "Itens")]
    public class Itens
    {
        [XmlAttribute(AttributeName = "tipo")]
        public string Tipo { get; set; }
        [XmlAttribute(AttributeName = "nomeArquivo")]
        public string NomeArquivo { get; set; }
        [XmlAttribute(AttributeName = "extensaoArquivo")]
        public string ExtensaoArquivo { get; set; }
        [XmlAttribute(AttributeName = "conteudoArquivo")]
        public string ConteudoArquivo { get; set; }
    }

    [XmlRoot(ElementName = "CriacaoClasse")]
    public class CriacaoClasse
    {
        [XmlElement(ElementName = "Itens")]
        public List<Itens> Itens { get; set; }
    }

}
