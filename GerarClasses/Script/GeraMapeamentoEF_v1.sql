
DROP TABLE #dadoProcessar
DROP TABLE #cloneDadoProcessar


SELECT 
db.name dbName,
tb.name AS nomeTabela, 
tb.object_id AS objTabela, 
c.name AS nomeColuna,
c.column_id AS column_id,
t.name AS tipo,
c.max_length AS tamanhoMax,
c.is_nullable,
c.is_identity,
dc.definition AS padrao,
SCHEMA_NAME(tb.schema_id) AS schemaName
,ROW_NUMBER() OVER(ORDER BY tb.object_id,c.column_id) rnk
INTO #dadoProcessar
FROM sys.databases db
INNER JOIN sys.tables AS tb ON DB_ID() = db.database_id
INNER JOIN sys.columns c ON c.object_id = tb.object_id
INNER JOIN sys.types t ON t.system_type_id = c.system_type_id
LEFT JOIN sys.default_constraints dc ON dc.object_id = c.default_object_id
--WHERE tb.name = 'Funcionario'
--OR tb.name = 'SituacaoDocumento'


--SELECT * FROM #dadoProcessar


SELECT dbName,
       nomeTabela,
       objTabela,
       nomeColuna,
	   column_id,
       tipo,
       tamanhoMax,
       is_nullable,
       is_identity,
       padrao,
	   schemaName,
	   rnk
INTO #cloneDadoProcessar
FROM #dadoProcessar

DECLARE @dbName AS VARCHAR(200),
		@nomeTabela AS VARCHAR(200),
		@objTabela AS INT,
		@nomeColuna AS VARCHAR(200),
		@column_id AS INT,
		@tipo AS VARCHAR(200),
		@tamanhoMax AS INT,
		@is_nullable AS BIT ,
		@is_identity AS BIT ,
		@padrao AS VARCHAR(200),
		@rnk AS INT,
		@resultado AS VARCHAR(MAX) = '',
		@linhas AS VARCHAR(MAX) = '',
		@tabelaProcessando AS VARCHAR(200) = '',
		@schemaNameProcessando AS VARCHAR(100) = '',
		@foreignMap AS VARCHAR(MAX) = '',
		@schemaName AS VARCHAR(200),

		@classeMap AS VARCHAR(MAX) = '',
		@classeConstrutorParam AS VARCHAR(MAX) = '',
		@classeConstrutor AS VARCHAR(MAX) = '',
		@classeAtributos AS VARCHAR(MAX) = '',
		@classeMetodo AS VARCHAR(MAX) = '',
		@classeTipoVarConvertido AS VARCHAR(MAX)

WHILE(EXISTS(SELECT 1 FROM #cloneDadoProcessar))
BEGIN

	--########################### RECUPERA DADOS ###########################
	SELECT TOP 1 @dbName = dbName,
                 @nomeTabela = nomeTabela,
                 @objTabela = objTabela,
                 @nomeColuna = nomeColuna,
                 @column_id = column_id,
                 @tipo = tipo,
                 @tamanhoMax = tamanhoMax,
                 @is_nullable = is_nullable,
                 @is_identity = is_identity,
                 @padrao = padrao, -- REPLACE(REPLACE(@padrao,'(',''),')',''),
				 @schemaName = schemaName,
				 @rnk = rnk
	FROM #cloneDadoProcessar


	--########################### COMPLETA O BLOCO ###########################
	IF(@tabelaProcessando <> '' AND @nomeTabela <> @tabelaProcessando)
	BEGIN

		SET @resultado += '
################### CLASSE ###################
public class ' + @tabelaProcessando + '
{
	#region Construtores
	public ' + @tabelaProcessando + ' ()
	{

	}
		
	public ' + @tabelaProcessando + ' ('+ SUBSTRING(@classeConstrutorParam,1,LEN(@classeConstrutorParam)-1) +')
	{
' + @classeConstrutor + '
	}

	#endregion Construtores

	#region Atributos

' + @classeAtributos + '

	#endregion Atributos

	#region Métodos

	public void AlterarEntidade(' + @tabelaProcessando + ' entidade)
	{
' + @classeMetodo + '
	}

	#endregion Métodos
}



################### MAPEAMENTO ###################
		
public class ' + @tabelaProcessando + 'Map : IEntityTypeConfiguration<' + @tabelaProcessando + '>
{
	public void Configure(EntityTypeBuilder<' + @tabelaProcessando + '> builder)
	{
		builder.ToTable("' + @tabelaProcessando + '", "' + @schemaNameProcessando + '");
				
' + @linhas + '
				
' + @foreignMap + '
				
	}
}
'

		--########################### RESETA VARIAVEIS
		SET @foreignMap = ''
		SET @linhas = ''

		SET @classeConstrutorParam = '' 
		SET @classeConstrutor = '' 
		SET @classeAtributos = '' 
		SET @classeMetodo = ''

		SET @schemaNameProcessando = @schemaName
		SET @tabelaProcessando = @nomeTabela

	END

	--########################### INICIA VARIAVEIS ###########################
	IF(@tabelaProcessando = '')
	BEGIN
		SET @schemaNameProcessando = @schemaName
		SET @tabelaProcessando = @nomeTabela
	END 

	--########################### ADICIONA NA LINHA DO MAPEAMENTO ###########################
	SET @linhas += CHAR(9) + CHAR(9) + 'builder.Property(x => x.' + @nomeColuna + ').HasColumnType("' + UPPER(@tipo) + '")'
	IF(@tipo = 'varchar')
	BEGIN
		SET @linhas += '.HasMaxLength(' + CONVERT(VARCHAR, @tamanhoMax) + ')'
	END
	
	SET @linhas += '.IsRequired(' + CASE WHEN @is_nullable = 1 THEN 'false' ELSE 'true' END + ')'
	IF(@padrao IS NOT NULL)
	BEGIN
		SET @linhas +=  
		CASE @tipo
		WHEN 'bit' THEN
			'.HasDefaultValue(' + CASE WHEN REPLACE(REPLACE(@padrao,'(',''),')','') = 1 THEN 'true' ELSE 'false' END + ')'
		ELSE
			'.HasDefaultValue(' + REPLACE(REPLACE(@padrao,'(',''),')','') + ')'
		END  
	END

	SET @linhas += ';' + CHAR(13)+CHAR(10)

	--########################### ADICIONA NA LINHA DO MAPEAMENTO @foreignMap ###########################
	select 
		@foreignMap += CHAR(9) + CHAR(9) + 'builder.HasOne(x => x.' + pk_tab.name + ').WithMany('+ LOWER(SUBSTRING(pk_tab.name,1,1)) +' => '+ LOWER(SUBSTRING(pk_tab.name,1,1)) +'.'+ @nomeTabela +'s).HasForeignKey('+ LOWER(SUBSTRING(@nomeTabela,1,1)) +' => '+ LOWER(SUBSTRING(@nomeTabela,1,1)) +'.'+ @nomeColuna +');'+ CHAR(13)+CHAR(10)
	from sys.foreign_keys fk
		inner join sys.tables fk_tab on fk_tab.object_id = fk.parent_object_id
		inner join sys.tables pk_tab on pk_tab.object_id = fk.referenced_object_id
		inner join sys.foreign_key_columns fk_cols on fk_cols.constraint_object_id = fk.object_id
		inner join sys.columns fk_col on fk_col.column_id = fk_cols.parent_column_id
										AND fk_col.object_id = fk_tab.object_id
		inner join sys.columns pk_col on pk_col.column_id = fk_cols.referenced_column_id
											AND pk_col.object_id = pk_tab.object_id
	WHERE fk_tab.name = @nomeTabela
	AND fk_col.name = @nomeColuna
	

	--########################### MAPEAMENTO - RESULTADO BASE ###########################
	/*
	builder.Property(x => x.IdLocalFisico).HasColumnType("INT").IsRequired(false);
    builder.Property(x => x.Matricula).HasColumnType("VARCHAR").HasMaxLength(100).IsRequired(true);

	builder.HasOne(x => x.Pessoa).WithMany(p => p.Funcionarios).HasForeignKey(f => f.IdPessoa);
	
	
	################################################################################################################################
	MONTA CLASS
	################################################################################################################################
	*/

	SET @classeTipoVarConvertido = 
		CASE @tipo 
			when 'bigint' then 'long'
			when 'binary' then 'byte[]'
			when 'bit' then 'bool'
			when 'char' then 'string'
			when 'date' then 'DateTime'
			when 'datetime' then 'DateTime'
			when 'datetime2' then 'DateTime'
			when 'datetimeoffset' then 'DateTimeOffset'
			when 'decimal' then 'decimal'
			when 'float' then 'double'
			when 'image' then 'byte[]'
			when 'int' then 'int'
			when 'money' then 'decimal'
			when 'nchar' then 'string'
			when 'ntext' then 'string'
			when 'numeric' then 'decimal'
			when 'nvarchar' then 'string'
			when 'real' then 'float'
			when 'smalldatetime' then 'DateTime'
			when 'smallint' then 'short'
			when 'smallmoney' then 'decimal'
			when 'text' then 'string'
			when 'time' then 'TimeSpan'
			when 'timestamp' then 'long'
			when 'tinyint' then 'byte'
			when 'uniqueidentifier' then 'Guid'
			when 'varbinary' then 'byte[]'
			when 'varchar' then 'string'
			else 'UNKNOWN_' + @tipo
		END + CASE WHEN @is_nullable = 1 THEN '?' ELSE '' END

	SET @classeConstrutorParam += @classeTipoVarConvertido + ' ' + LOWER(SUBSTRING(@nomeColuna,1,1)) + SUBSTRING(@nomeColuna,2,LEN(@nomeColuna)) + ', '

	SET @classeConstrutor += CHAR(9) + CHAR(9) + @nomeColuna + ' = ' + LOWER(SUBSTRING(@nomeColuna,1,1)) + SUBSTRING(@nomeColuna,2,LEN(@nomeColuna)) + ';' + CHAR(13)+CHAR(10)

	SET @classeAtributos += CHAR(9) + 'public ' + @classeTipoVarConvertido + ' ' + @nomeColuna + ' { get; private set; }' + CHAR(13)+CHAR(10)

	SET @classeMetodo += CHAR(9) + CHAR(9) + @nomeColuna + ' = entidade.' + @nomeColuna + ';' + CHAR(13)+CHAR(10)



	--########################### CLASSE - RESULTADO BASE ###########################
	/*
	public class Pedido
	{
		#region Construtores
		public Pedido ()
		{

		}
		
		public Pedido (int id)
		{
			Id = id;
		}

		#endregion Construtores

		#region Atributos

		public int Id { get; private set; }

		#endregion Atributos

		#region Métodos

		public void AlterarEntidade(Pedido entidade)
		{
			IdSitGed = entidade.IdSitGed;
		}

		#endregion Métodos
	}
	
	*/

	--EXCLUI DADOS USADO
	DELETE FROM #cloneDadoProcessar WHERE rnk = @rnk

END


SELECT @resultado
