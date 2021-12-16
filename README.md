# DOUTORADO DANIEL VIEIRA

* [tese.pdf](LATEX_tese/tese.pdf)


## 16/12/21
* [x] escrever titulo
* [ ] perguntar sobre o titulo, se eh isso mesmo
* [x] escrever resumo
* [x] escrever equacoes de `get_xr`
* [x] escrever equacoes de `get_x0`
* [x] mudar os textos auxiliares da Tese para ingles
* [x] colocar LATEX no GITHUB
- [ ] ajustar textos no equacionamento de linearizacao
	- [ ] mudar texto para ingles
	- [ ] colocar *underbrace* e *overbrace*


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
