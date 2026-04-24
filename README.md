# DOUTORADO DANIEL VIEIRA

* [tese.pdf](LATEX_tese/tese.pdf)


## Support Images

- DOUTORADO/LATEX/Artigo/images/
- DOUTORADO/LATEX/Artigo/images_support/



## 15/09/22

  * [ ] Passar linearizacao para antes do controle preditivo
  
  * [ ] Pode haver repeticao das matrizes
  
  * [ ] Trabalhar o capitulo 3.
      - [x] descricao do problema
      - [ ] referencias na literatura
        - [x] egidio 37 -> tempo discreto, mas vai para um ciclo limite buscando desempenho
        - [x] egidio 36 -> segundo artigo, ja trabalha no tempo continuo
          - [x] estudar teorema 2 ? 
        - ~~[.] pequena discussao sobre controle por estados e time-dependent~~
      - [x] citar trabalhos anteriores:
        - [x] marcio
        - [x] patino
        - [x] benmiloud
        - [x] matheus
      - [x] contribuicoes do trabalho atual
      - [x] falar que o problema de controle � dificultado pela presenca de dwell-time consttraints.

  * [ ] removi referencia de `sanchez2019` e `xu2024`

## 23/06/22

- [x] Qual um bom programa pra fazer anotacoes? Voce conhece algum?

- [x] Falar sobre as citacoes: 
	tenho: biochemical reactions, urban traffic e power converters


## 07/06/22

[ ] matriz A1x + B1*u1

	mudar B1*u1 -> b_{\sigma(t)}

	b_1 = Bu_1

[ ] referencias na literatura

	google scholar :: switched affine systems

	campos de aplicacao (tempo continuo)

	3 � um numero bom


[ ] reacoes bioquimicas


[ ] Por que eh importante estudar esse assunto? nao somos os unicos etudando isso, outros estudam em varias areas?


[ ] O que falar sobre o patino?

	definiu uma trajetoria alvo usando programacao nao linear, usou esse alvo no custo de controle preditivo em termos de um erro.


[ ] Matheus chega em um problema de otimizacao que eh convexo


[ ] Matheus estava trabalhando com o caso particular do modelo afim em que a matriz A eh constante

	A constante
	b_{\sigma(t)} = Bu_{\sigma(t)}


[ ] Passar linearizacao para antes do controle preditivo


[ ] pode haver repeticao das matrizes


* Escrever `Motivation`, `Contributions of the present work` e `Outline of the remaining chapters`

	* [ok] Introduzir sistemas chaveados afins e dificultade de um sistema chaveado afim de conduzir a trajetoria para um ponto

	* Referencias do problema na literatura


## 17/05/22

* [ok] como colocar negrito apenas em uma \mathbf 
	tentar usar:: \boldsymbol
	pacote `bm`

* [ok] perguntar sobre cronograma

	* [ok] quais sao as etapas agora e prazos?
		- extensao (generalizacao) de caso tempo final livre na otimizacao
			1 semestre
		- elaboracao de um artigo com resultados ateh o momento
			.5 semestre (elaboracao e submissao)
		- aplicacao que envolvesse numero maior de estados de chaveamento 
			// talvez um novo circuito 
			1 semestre
		- ?? experimental nao precisa prometer

		- elaboracao da tese final (defesa)
			1 semestre

		tabela com colunas em semestre

	* [ok] como funciona o processo de qualificacao?

		* o que eu tenho que mostrar nesse texto? 
			- apresentar o problema e relevancia, 
			- trabalhos previos, 
			- formulacao matematica

* terminar prediction equation

## 14/04/22

pre-escrita Controle preditivo

* [ ] convencao de escrita vetores / matrizes nas equacoes (negrito, UPPER, ...)

matrizes: italico e UPPER
negritos: matrizes formatas por combinacao de outras matrizes
vetores : italico

## 30/03/22

luenberg -> programacao linear / nao linear

* [ok] perguntar sobre referencias e material para estudar otimizacao

* [ok] algum material fala sobre as diferenças entre tipo de metodos `quadprog`?
	* trust-region-reflective
	* interior-point-convex
	* active-set

* [ok] pedir dicas para capitulo 2

	* descricao do problema
	* calculo da condicao inicial
	* sequencia de modos predefinida (falar sobre a otimizacao para encontrar modos aqui?)
	* calculo dos estados Xr nominal, dado o instante de chaveamento e sequencia de modos
	* descricao da funcao custo
	* montar solucao com fmincon
	* usar exemplos `integrador`, `patino_1` e `patino_2`
	* conclusoes capitulo 2

* [ok] capitulo 3

	* descricao do controle preditivo
	* explicar porque precisamos linearizar o problema 
	* apresentar procedimento de linearizacao
	* problema de controle
    	* funcao custo
    	* equacao de predicao
		* restricoes
	* aplicacao com `integrador`, `patino_1` e `patino_2`
	* conclusoes dos resultados da aplicacao da lei de controle

* [ok] capitulo 4

	* cronograma
	* conclusoes gerais do trabalho

## 17/03/22

* [ ] plano de trabalho e cronograma na qualificacao

## 11/03/22

* [ ] Escrever motivaCAo e contribuiCAo

sistemas lineares chaveados sao muito importantes na engenharia

uma dificultade em particular suge quando estabilizar conduzir para uma trajetoria ciclic, nao esta muito explorado

diferentes modelos afins

baminou

marcio, abordou classe particular de sisteas afins

mateus, 

ideia chave
- sistemas chaveados importantes
- controle traj ciclica nao explorada
- otimalidade buscando preditivo, mas ha limitacoes
- mexer nos instantes de chaveamento, explorando um modelo linearizado

linearizacao dos instantes de chaveamo

a relacao entre instantes de chaveamento e o estado resultante eh nao linear. 

generalizar o traablho do mateus, que trabalha uma classe particular

lineariza o modelo discreto

colocar eq (1) benmiloud

* [ ] fazer caixinhas

p q eh importante estudar sistemas chaveados?
p q eh importante explorar trajetorias ciclicas?
q trabalhos foram feitos?


[benmiloud2018]
However, the proposed controllers are developed by a deep analysis of the converter dynamics and the possibility of generalisation is not straightforward.

Eh aqui a nossa contribuicao??

---
In addition, a predictive approach has been proposed in [15]
(Patino)

Melhor ler isso tambem

Uai, já li!

---


Q:
Como definir Switched affine systems
Sempre entendi affine systems como sistemas lineares, Switched nao torna ele nao linear?

Sistemas afins sao sistemas na forma: A.X + B



## 17/02/22


* [ ] ComeCar a escrever um Pre-escrita

	TITULO: ROBUST CONTROL OF LINEAR SYSTEMS WITH SWITCHED ACTUATORS SUBJECTED TO DWELL-TIME CONSTRAINTS	

	REFERENCIAS:

		-> Márcio Santos Vieira
			- [2013] :: Controle Preditivo de Sistemas com Atuadores Sujeitos a Restrições temporais de Chaveamento
			
			* Inicio da linha de estudos, preditivo calculado a cada iteracao para encontrar uma solução atraves de uma otimizacao sujeita a restricoes temporais com MILP (Mixed Integer Linear Programming)

		-> Matheus Henrique Marcolino
			- [2018] :: Stabilization of Periodic Trajectories Through Recending Horizon Optimization of Switching Times
			- [2020] :: Predictive Control of Linear Systems with Switched Actuators Subject to Dwell-Time Constraints

			* Separacao do problema em 2 etapas: 
    			* uma primeira como um problema de otimizacao para calcular uma trajetória ciclica que respeita as restricoes de tempo do sistema
    			* uma segunda como um problema de controle preditivo que calcula perturbacoes de tempo nos instantes de chaveamento para levar o sistema controlado para a trajetoria ciclica encontrada inicialmente.

			
		-> D. Patino
			- [2010] :: A predictive control approach for DC-DC power converters and cyclic switched systems

			* Estou usando, em especial, a maneira que o autor desse arquigo calcula a trajetoria de referencia

		-> Mohammed Benmiloud,
			- [2019] :: On the Local Stabilization of Hybrid Limit Cycles in Switched Affine Systems

	CONTRIBUICAO:

		-> Generalizacao do problema de controle, possibilitando o uso do controlador em sistemas nao lineares, com restricao temporais que estabilizam em uma trajetoria ciclica e que possuam comportamento dinamico variante no tempo.
		
		Extender o trabalho do Matheus para `Switched Affine Systems`

	COMO VOU APRESENTAR ISSO?

		{palta de discussao da reuniao}




	bad practice ::
		-> Use of nouns instead of verbs
		-> Use of big words (vague words)
		-> Too much distance between the subject and the main verb of the sentence

	good practice ::
		-> Use the active voice
		-> Write with verbs
		-> Eliminate negatives
			- She was not often right => She was usually wrong  
			- She did not want to perform the experiment incorrectly => She wanted to perform the experiment correctly
		-> Eliminate `there are` / `there is`
			- There are several mechanisms that could explain the findings => Several mechanisms could explaind the findings

			She planned to take the test on Tuesday


	Common clutter ::
		-> Dead weight words and phrases
			- As it is well known
			- As it has been shown
			- It can be regarded that
			- It should be emphasized that

		-> Empty words and phrases
			- basic tnets of
			- methodologic
			- important

		-> Long words or phrases that coud be short
			- muscular and cardiorespiratory performance

		-> Unnecessary jargon and acronyms
			- muscular and cardiorespiratory performance
		
		-> repetitive words or phrases
			- studies/examples
			- illustratre/demonstrate
			- challengs/difficulties
			- succesful solutions

		-> Adverbs
			- very, really, quite, basically, generally, ...


	Long phrases that could be short ::

		- Are of the same opinion => agree
		- Less frequently occurring => rare
		- All three of the => the three
		- Give rise to => cause
		- Due to the fact that => because
		- Have an effect on => affect


	(entender o que vc quer escrever, qual o objectivo)
	(escrever com verbos)


- Notas:
  - Texto cientIfico: https://www.coursera.org/learn/sciwrite
    - pre-escrita (70%)
    - redacao (10%)
    - revisao (20%)

## 04/01/22
* [ ] como fazer para escrever um texto e ainda manter as equacoes alinhadas (equacao 3.13)
* [ ] tem como agrupar um texto com equacao para que eles nao fiquem em paginas separadas?
* [ ] converter codigo para C++ e calcular tempo de cada ciclo de computacao para resolver o controle preditivo 


## 16/12/21
* [x] escrever titulo
* [x] perguntar sobre o titulo, se eh isso mesmo
* [x] escrever resumo
* [x] escrever equacoes de `get_xr`
* [x] escrever equacoes de `get_x0`
* [x] mudar os textos auxiliares da Tese para ingles
* [x] colocar LATEX no GITHUB
- [ ] ajustar textos no equacionamento de linearizacao
	- [x] mudar texto para ingles
	- [x] colocar *underbrace* e *overbrace*


## 13/12/21
- [x] adicionar arquivos LATEX no github
- [x] escrever equacao linearizacao
* [ ] ~~escrever equacionamento  `get_x0()`~~
- [ ] escrever equacionamento  `get_xr()`

- Notas:
	- plugin LaTeX para melhorar visualização MATLAB (*matlab-prettifier*):
		- https://ctan.org/pkg/matlab-prettifier?lang=en

	- criar comando LaTeX para facilitar uso de instruções (cores por exemplo) :	
		```latex
		\newcommand{\red}[1]{{\color{red}#1}}
		\red{Texto ou equação}
		```
	

## 19/11/21

- [x] organizar codigo
- [x] commit github
- [ ] fazer caso para exemplo 2 patino

* [x] gerar modelo latex qualificacao
- [ ] ~~documentar programa de otimizacao (`get_xr`)~~
- [ ] ~~documentar programa de otimizacao (`get_x0`)~~
* [x] documentar equacionamento de linearizacao
	

## 14/04
- [x] ajustar funcao custo

  
        J(T, Om, s) = min(integral [x(t) - x_inf]'*Q*x(t) - x_inf]dt) {de 0 a Tp}


- [x] colocar condicao inicial como parametro de otimizacao (conferir restricoes)

        Mostrar como impus a restricao de condicao inicial 
        (talvez tenha que ajustar algum parametro de tolerancia)

- [x] implementar caso com mais modos de controle (2o caso artigo)

## 27/04

- [x] implementar ex. 2

## 14/05

- [x] implementar calculo de condicao inicial no otmizador

- [x] calcular caso 2 com implementacao

## 27/05

- [ ] documentar trabalhos

## 01/06

Ultrafast PDFLaTeX with precompiling

	http://www.stackprinter.com/export?service=tex.stackexchange&question=79493&printer=false&linktohome=true
	
	https://web.archive.org/web/20160912114941/http://www.howtotex.com:80/tips-tricks/faster-latex-part-iv-use-a-precompiled-preamble/


export_fig -transparent -painters nome.pdf

- [ ] expandir equacao linearizada



## REQUIREMENTS

### Multi-Parametric Toolbox 3

https://www.mpt3.org/


## INSTALL TEXLIVE PACKAGES

	>> tlmgr install natbib