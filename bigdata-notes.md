## Data Access

### PIG
#### Casos de utilização
	- ETL
	- Pesquisa em dados "crus"
	- Processamento de dados iterativos
	
#### Como o Pig é executado num cluster
	- Acessa o YARN através de jobs MapReduce ou Tez
		-- MapReduce é uma lib Java que utiliza os conceitos "map" e "reduce" para extrair informação do HDFS
		-- Tez é uma lib que permite construir "frameworks" que acessam o YARN utilizando tarefas acíclicas direcionadas a grafos para processar os dados do HDFS 
	- Pig utiliza "Pig Latin" como linguagem de ETL, que permite descrever fluxos de dados para definir como os dados serão processados e transformados(ETL)
	
### Hive
#### Como o Hive funciona no Hadoop
	- NÃO armazena dados, exatamente, mas metadados que representam tabelas de modo similar a um RDBMS
	- permite acesso aos dados do HDFS através de uma linguagem semelhante ao SQL
	- permite organizar os dados em forma de tabelas através de metadados

### Hive
#### Tabelas
	- Cada tabela no Hive corresponde a um diretório no HDFS
	- As tabelas do Hive são armazenadas em no "Hive metastore"
		-- "Hive metastore" permite definir um banco de dados relacional(MSQL por default, Postgres, Oracle etc), manipular os dados do HDFS
	- HiveQL é um subconjunto do SQL e é a linguagem utilizada pelo Hive
	- HiveQL converte suas instruções para "Hadoop jobs", que podem ser despachados para Tez, MapReduce ou Spark
	- Os dados das tabelas gerenciadas pelo Hive(ou tabelas INTERNAS), são armazenados no diretório "Hive warehouse" (default: /apps/hive/warehouse/)
	- Tabelas NÃO gerenciadas pelo Hive(ou tabelas EXTERNAS), podem ser armazenadas em qualquer lugar do HDFS.
	- DROP em tabelas INTERNAS apagam DADOS E METADADOS
	- DROP em tabelas EXTERNAS apagam SOMENTE OS METADADOS
	- Tabelas "Bucketed" são eficientes para desempenhar bem "map-side jobs", que é consideravelmente mais eficiente do que "reduce-side jobs"
	- Tabelas "Partitioned" oferecem vantagens de desempenho quando organizadas em subdiretórios baseados em colunas específicas, já que cláusulas "WHERE" 
	  são executadas somente rastreando dados dos diretórios especificados na própria cláusula "WHERE".

#### HCatalog
	- HCatalog é uma extensão do Hive para que outros frameworks como "Pig" e "Java MapReduce" possam acessar o HDFS através dos metadados do Hive
	- HCatalog permite compartilhar dados entre desenvolvedores Pig, Hive e Java(MapReduce) em uma "view" comum
	
#### Tez: benefícios
	- Tez roda sobre o YARN e executa as DAGs(Direct Acyclic Graph) mais rapidamente e mais eficientemente do que MapReduce
	- Hive e Pig são mais eficientes quando rodam sobre Tez(quase sempre)
	
### Storm
#### Onde se utiliza e alguns exemplos
	- Streaming de dados em tempo-real através de "storm bolts"
	- Storm se integra com o YARN através do "Apache Slider"
	- Storm é considerado para utilizar em operações que exigem governança e segurança de dados(operações com cartão de crédito, por exemplo)
	- Prevê eventos indesejados de negação de crédito de cartão de crédito, por exemplo, em tempo real
	- Otimiza resultados positivos baseados em análise em tempo-real para, por exemplo, oferecer descontos no varejo para clientes específicos
	
### HBase
#### O que é?
	- Banco de dados não-relacional que roda no topo do HDFS
	- Escrita/Leitura em tempo-real para acessar bases de dados gigantescas
	- API em Java 

#### Para que serve?
	- Acesso em tempo-real a bases de dados gigantescas
	- Criação de tabelas gigantes para armazenamento multi-estruturado ou dados esparsos(dados não-estruturados)
	- É possível criar "tickers" na área financeira para monitorar ações(bolsa de valores), na ordem de mais de trinta mil leituras/segundo
	- Monitoramento de sistemas de segurança web em tempo-real através de eventos em logs na ordem de bilhões de linhas

### Spark
#### Componentes
	- Spark SQL: Aceita HiveQL ou SQL básico para executar queries;
	- Spark Streaming: Permite manipular streaming de dados escaláveis, tolerante a falhas em tempo-real
	- Spark MLib: Biblioteca de "Machine Learning". Provê algoritmos padrão de "machine learning" fáceis de implementar e escaláveis
	- GraphX: Para trabalhar com grafos e computação paralela
	
#### Como aplicações com Spark executam o YARN
	- Cluster mode: Diver Spark roda dentro do processo ApplicationMaster, que é gerenciado pelo YARN sobre o Cluster, e o cliente pode deixar o 
	  ciclo do Spark após a inicialização da aplicação
	- Client mode: o driver roda no processo do cliente. O AplicationMaster é usado apenas para requisitar recursos ao YARN, e a aplicação precisa
	  permanecer rodando no ciclo do Spark até o fim.

### Solr
#### Propóstio
	- Plataforma de pesquisa de dados armazenados em HDFS no Hadoop 


## Data Management

	
### HDFS
#### Intro
	- HDFS(Hadoop Distributed File System) é o sistema de armazenamento de dados do Hadoop
	- HDFS é escalável: Se for necessário mais armazenamento, é preciso apenas adicionar um "nó" ao cluster
	- HDFS é tolerante à falhas: Se um nó falha, o dado não é perdido
	- O "NameNode" é o "nó-mestre" que mantém o "namespace" do sistema de arquivos e envia comandos aos "DataNodes" 
	- Um "StandBy NameNode" pode ser configurado para prover alta-disponibilidade ao "NameNode"(redundância)
	
#### Replicação de bloco
	- Grandes dados em arquivos são separados em blocos que são distribuídos no cluster
	- O "NameNode" rastreia todos os nomes de arquivos e pastas, e também as localizações dos blocos nos "DataNodes"
	- Os "DataNodes" armazenam dados instruídos pelo "NameNode"
	
### YARN
#### Intro
	- Prover o componente de processamento do Hadoop
	- O "ResourceManager" tem uma "agendador", que é responsável por alocar recursos das várias aplicações que estão executando no cluster, de acordo
	  com suas restrições, tais como, capacidade de enfileiramento e limites de usuário
	- Os "NodeManagers" executa tarefas dirigidas pelo "ResourceManager"
	- A "ApplicationMaster" tem a responsabilidade de negociar containers de recursos apropriados do agendador, rastreando o seu status, e monitorando
	  o seu progresso
	 

## Data Governance and Workflow

### Falcon
#### Intro
	- Falcon simplifica o desenvolvimento e gerenciamento de pipelines de processamento de dados com uma camada superior de abstração, levando codificação 
	  complexa do processamento de dados aplicativos, fornecendo uma solução "out-of-the-box" de serviços de gerenciamento de dados.
	- Operadores de Hadoop podem usar a UI web do Falcon ou a interface de linha de comando para criar pipelines de dados, que consiste em definições
	  de localização de clusters, consumo de dados, e lógica de processamento 
	  
### Falcon
#### Entidades
	- Cluster: Define onde o dado e os processos são armazenados 
	- Feed: Define quais conjuntos de dados podem ser limpos e processados
	- Processo: Consome os "Feeds", invoca o processamento lógico, e produz outros "feeds"
	
### Atlas
#### Intro
	- Projetado para trocar metadados com outras ferramentas dentro ou fora da "pilha Hadoop", assim possibilitando um controle de governança "agnóstica" de 
	  plataforma que efetivamente entrega o cumprimento dos requisitos
	- tags hierarquicas de controle de acesso a dados no HDFS 
	- controle de origem/linhagem de dados manipulados por ferramentas como Hive, Spark, Pig, através de metadados 
	
	  
### Sqoop
#### Intro 
	- Sqoop é uma ferramenta para transferir dados entre um banco de dados relacional e o Hadoop 
	- Funciona em ambas as direções: Tanto carregando de um EDW(Enterprise Datawarehouse) para processamento, e o resultado pode ser exportado de volta para 
	  o Hadoop.

### Flume
#### Intro 
	- Flume permite que usuários do Hadoop "ingiram" uma quantidade grande de dados via streaming do HDFS para armazenamento 
	- Tipos comuns desses streams: logs de aplicação, dados de máquina e sensores, dados de geo-localização, e dados de mídia social

### Kafka
#### Intro 
	- Kafka é um enfileirador de mensagens
	- Kafka também é usado para substituir enfileiradores de mensagem tradicionais como JMS e AMQP por conta do seu rendimento, escalabilidade e confiança

#### Componentes
	- Topic: Categoria definida pelo usuário para que a mensagem seja publicada
	- Producer: publica mensagens para um ou mais tópicos
	- Consumer: assina tópicos e processa as mensagens publicadas
	- Broker: Gerencia a persistência e replicação dos dados de mensagens 

### Cloudbreak
#### Intro
	- ferramenta de provisionamento de Clusters Hadoop em plataformas de cloud como Amazon e Azure
	- Usa o Ambari Blueprint para configurar dinamicamente e provisionar clusters HDP(Horton Data Plataform) na nuvem

### Zookeeper
#### Papel do Zookeeper
	- Prover configuração de serviços distribuída
	- Prover sincronização de serviços
	- Prover um registro de nomes para sistemas distribuídos 

### Oozie
	- É uma interface web para agendamento de jobs do Hadoop
	- Um agendamento no Oozie é uma sequência de ações, que podem envolver um script Pig, uma query Hive, um job MapReduce e asism por diante
	- Oozie mantém um "job" coordenador que é "engatilhado" quando um workflow é executado 
	
### Ranger 
	- É um framework centralizado de segurança para gerenciar acesso com alta granularidade sobre ferramentas como Hive e HBase
	- Usando um console, administradores podem facilmente gerenciar políticas de acesso à arquivos, pastas, bancos de dados, tabelas ou colunas 

### Knox 
	- Prover um "perímetro" de segurança(proxy) para clusters Hadoop 
	- O Knox Gateway provê um ponto-único de acesso para TODAS as interações REST com clusters Hadoop 
	- Knox pode trabalhar diretamente com o Kerberos para controlar autenticação e autorização de usuários 
	
	
	
## Other components

### Thrift
#### Intro 
	- É uma linguagem de definição de interface e um protocolo binário que é utilizado para criar serviços em multiplas linguagens
	- Usado como uma chamada RPC 
	- Combina uma pilha de aplicação com uma engine geradora de códigos para construir serviços "cross-plataform"
	
#### Benefícios
	- Alternativa ao SOAP
	- Biblioteca simples e enxuta
	- Sem framework para implementar
	- Sem XML
	- O formato do nível de aplicação e o formato do nível de serialização estão separados de forma clara, e podem ser modificados de forma independente
	- Estilos de serialização: binary, HTTP-friendly and compact binary 
	- Sem dependências de "builds", software-padrão. Sem mistura de licenças incompatíveis
