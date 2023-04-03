#include "rwmake.ch"  
#INCLUDE "TOPCONN.CH" 
#IFNDEF WINDOWS     
	#DEFINE PSAY SAY
#ENDIF
//------------------------------------------                    
// Analista  - Raul Costa
// Descricao - Impressao do Pedido de Vendas
//             Customizado
// Cliente   - B&S Oil Tools
// Modulo    - SIGAFAT
// DtCriacao - 28/12/21 - Atualizacao 24/05/22
//-----------------------------------------

************************
User Function PEDVENDA()
************************
nLastKey:= 0 
li:=0

cPerg:=PADR("BSPVEN",10)

CriaPerg()

If	Pergunte(cPerg,.T.)=.F.
	Return
Endif	

DbSelectArea("SC5")
DbSetOrder(1)
DbSeek(xFilial("SC5")+MV_PAR01)
cNumped := strzero(val(MV_PAR02),TamSX3('C5_NUM')[1])
Do While !EOF() .and. (strzero(val(C5_NUM),TamSX3('C5_NUM')[1])<= cNumped) .and. (xFilial("SC5")=C5_FILIAL)
   cNum     := C5_NUM
   cNumRev  := C5_NUMREV
   cDataRev := C5_DATAREV
   cSolic   := C5_PCM
   cNumOrc  := C5_ORC
   cNumAEM  := C5_AEM
   dEmissao := C5_EMISSAO    
   cNumGlob := C5_AFM
   cTpFrete := C5_TPFRETE
   //cCCL		:= C6_CCL1
   //cCCLper	:= C6_CCLPER
   cCondPg  := C5_CONDPAG
   cTpEntr  := C5_TPENTR
   cAntec   := C5_ANTEC
   cTpInsp  := C5_TPINSP
   cCliente := C5_CLIENTE
   cLoja    := C5_LOJACLI
   cObserv  := C5_MENNOTA 

   nVlrTot  := nTotIPI:=0

   DbSelectArea("SA1")                // Cadastro de Clientes
   DbSetOrder(1)                      // Filial+Codigo+Loja
   DbSeek(xFilial()+cCliente+cLoja,.F.)
   If  Found()
       cNome   := SA1->A1_NOME 
       cNReduz := SA1->A1_NREDUZ 
       cEnd    := Alltrim(SA1->A1_END)
       cCep    := SA1->A1_CEP 
       cBairro := Alltrim(SA1->A1_BAIRRO)
       cMun    := Alltrim(SA1->A1_MUN)
       cEst    := SA1->A1_EST
       cTel    := "("+Alltrim(SA1->A1_DDD)+") "+SA1->A1_TEL
       cFax    := "("+Alltrim(SA1->A1_DDD)+") "+SA1->A1_FAX
       cCNPJ   := SA1->A1_CGC
       cIEst   := SA1->A1_INSCR
       cEndCob := Alltrim(SA1->A1_ENDCOB)
       cEndEnt := Alltrim(SA1->A1_ENDENT)
       cCepCob := SA1->A1_CEPC //CEP Cobrança
   Else
       cNome   := "****** NAO CADASTRADO *********"
       cNReduz := "** NAO CADASTRADO **"
       cEnd    := Replicate("*",35)
       cCep    := "00000000"
       cBairro := Replicate("*",25)
       cMun    := Replicate("*",20)
       cEst    := "**"
       cTel    := Replicate("*",18)
       cFax    := Replicate("*",18)
       cCNPJ   := Replicate("0",14)
       cIEst   := Replicate("0",14)
   	   cEndCob := "***** NAO CADASTRADO ******"
	   cEndEnt := "***** NAO CADASTRADO ******"
       cCepCob := "00000000"
   Endif    

   cEstado	:= GetMV("MV_ESTADO")
   Aliq    := 0
   DbSelectArea("SA1")
   If SA1->A1_EST==cEstado
      Aliq:=GetMV("MV_ICMPAD")
   Elseif SA1->A1_EST=="EX"
      Aliq:=0
   Else  
      Aliq:=12
   Endif   
   
   cDescPG:=Posicione("SE4",1,xFilial("SE4")+cCondPg,"E4_DESCRI")   //Condição de Pagamento

   ****> Obter os Itens em SC6

   DbSelectArea("SC6")                   // * Itens do Orçamento

   Filial:=xFilial("SC6")

   cQry:="SELECT C6_ITEM, C6_PRODUTO, C6_PRCVEN, C6_VALOR, "
   cQry+="C6_ENTREG, B1_DESC, B1_POSIPI, B1_IPI, F4_IPI, F4_DESTACA, "
   If MV_par03 = 1                    
      cQry+="QUANT=C6_QTDLIB "
   Else
      cQry+="QUANT=C6_QTDVEN-C6_QTDENT "
   Endif
   cQry+="FROM "+RetSqlName("SC6")+" C6, "+RetSqlName("SB1")+" B1, "+RetSqlName("SF4")+" F4 "
   cQry+="WHERE C6_FILIAL='"+Filial+"' "
   cQry+="AND C6_NUM='"+cNum+"' "
   cQry+="AND C6_PRODUTO=B1_COD "
   cQry+="AND C6_TES=F4_CODIGO "
   cQry+="AND C6.D_E_L_E_T_<>'*' AND C6.C6_BLQ<>'R' "
   cQry+="AND B1.D_E_L_E_T_<>'*' "
   cQry+="AND F4.D_E_L_E_T_<>'*' "
   cQry+="ORDER BY C6_ITEM"

   Tcquery cQry new alias "C6"   

   nOrdem:= 1
   nPag  := 1
   li    := 0
   nVias := 0

   Imprime()
   
   DBSelectArea("C6")
   DbCloseArea()

   DbSelectArea("SC5")
   DbSkip()
Enddo

dbSelectArea("SC5")
Retindex("SC5")
dbSelectArea("SC6")
Retindex("SC6")
dbSelectArea("SA1")
Retindex("SA1")
dbSelectArea("SB1")
Retindex("SB1")
dbSelectArea("SE4")
Retindex("SE4")

Return

*************************
Static Function Imprime()
*************************
Private oFont, cCode

oFont08n:= TFont():New( "Arial",,08,,.t.,,,,,.f.)
oFont08 := TFont():New( "Arial",,08,,.F.,,,,,.f.)
oFont09	:= TFont():New( "Arial",,09,,.f.,,,,,.f.)
oFont09n:= TFont():New( "Arial",,09,,.t.,,,,,.f.)
oFont10n:= TFont():New( "Arial",,10,,.t.,,,,,.f.)
oFont12n:= TFont():New( "Arial",,12,,.t.,,,,,.f.)
oFont14n:= TFont():New( "Arial",,14,,.t.,,,,,.f.)

impset := MV_PAR01
If impset == MV_PAR01
   oPrn := TAVPrinter():New()
   oPrn :SetPortrait() 
   oPrn :Setup() // para configurar impressora
endif                                           

FOR nVias = 1 To 1
    
    oPrn:StartPage()
    ImpCabec()
    ImpDet()
    ImpRodape()
    
Next    

oPrn:Preview()

MS_FLUSH()

Return .t.

**************************
Static Function ImpCabec()                     
**************************
liIni:=0

cBitMap:="\system\Logo Marca.jpg"

li:=liIni+50
oPrn:Box(li,050,li+280,1200)   //box 1 - Logo
oPrn:Box(li,1250,li+280,2350)   //box 2 - Pedido

oPrn:SayBitmap(li+10,080,cBitMap,290,196)   

li:=liIni+100
//Endereço
oPrn:Say(li,400,"B  &  S      O I L  T O O L S" ,oFont14n,100)
li:=li+60
oPrn:Say(li,400,"EQUIPAMENTOS INDUSTRIAIS LTDA" ,oFont12n,100)
li:=li+90
oPrn:Say(li,080,"Rua Alvaro Gomes de Castro, 298 - Quadra G - Lote 01 - Porto Seco Pirajá" ,oFont08n,100)
li:=li+30
oPrn:Say(li,080,"Tel.: (71)3646-6666 - CEP: 41.233-005 - Salvador - Bahia" ,oFont08n,100)
li:=li+32

li:=liIni+80
// Pedidos
oPrn:Say(li,1280,"PEDIDO DE VENDAS Nº "+cNum+"           REV. "+StrZero(cNumRev,2),oFont12n,100)
li:=li+60
oPrn:Say(li,1280,"Pedido Cliente Nº "+cNumAEM,oFont09n,100)
oPrn:Say(li,1870,"Global Nº "+cNumGlob ,oFont09n,100)
li:=li+60
oPrn:Say(li,1280,"Cotação Nº "+cSolic,oFont09n,100)
oPrn:Say(li,1870,"Orçam. Nº "+cNumOrc ,oFont09n,100)
li:=li+60
oPrn:Say(li,1280,"Data Emissão "+Dtoc(dEmissao)+"         Data Revisão "+Dtoc(cDataRev),oFont09n,100)
//oPrn:Say(li,2100,IIf(nOrdem>1," - continuacao"," "),oFont09,100)

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Impressao dos Dados do Cliente      ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
li:=li+100
oPrn:Box(li,050,li+220,2350)   //box 3 - Dados do Cliente //Alteracao li+240 realizada 24.05.2022

oPrn:Say(li+40,080,"Cliente",oFont09n,100)
oPrn:Say(li+40,345,cNome,oFont09,100)

oPrn:Say(li+40,1280,"CNPJ",oFont09n,100)
If	Len(Rtrim(cCNPJ))=14
	oPrn:Say(li+40,1550,Transform(cCNPJ,"@R 99.999.999/9999-99"),oFont09,100)
Else
	oPrn:Say(li+40,1550,Transform(cCNPJ,"@R 999.999.999-99"),oFont09,100)
Endif	
oPrn:Say(li+40,1890,"Insc.Estadual",oFont09n,100)
oPrn:Say(li+40,2110,cIest,oFont09,100)

oPrn:Say(li+90,080,"Local Emissao ",oFont09n,100)
oPrn:Say(li+90,345,cEnd+" - "+cBairro+" - "+cMun+" - "+cEst+" - CEP "+Trans(cCep,"@R 99999-999"),oFont09,100)

//oPrn:Say(li+140,080,"Local Cobranca",oFont09n,100) //Alteracao realizada retirada linha 24.05.2022
//oPrn:Say(li+140,345,cEndCob+" - CEP "+Trans(cCepCob,"@R 99999-999"),oFont09,100) //Alteracao realizada retirada linha 24.05.2022

oPrn:Say(li+140,080,"Local Entrega",oFont09n,100) //Alteracao realizada li+190 24.05.2022
oPrn:Say(li+140,345,cEndEnt,oFont09,100) //Alteracao realizada li+190 24.05.2022

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Impressao dos Dados do Pedido       ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
li:=li+260 
oPrn:Box(li,050,li+150,2350)   //box 4 - Dados gerais

oPrn:Say(li+40,080,"Cond. Pagto",oFont09n,100)
oPrn:Say(li+40,345,cDescPG,oFont09,100)

oPrn:Say(li+40,800,"Tipo Inspeção",oFont09n,100)
If cTpInsp = "1"
   oPrn:Say(li+40,1200,"TIPO A",oFont09,100)
Elseif cTpInsp = "2"
   oPrn:Say(li+40,1200,"TIPO B",oFont09,100)
ElseIf cTpInsp = "3"
   oPrn:Say(li+40,1200,"TIPO C",oFont09,100)
ElseIf cTpInsp = "4"
   oPrn:Say(li+40,1200,"NENHUMA",oFont09,100)
ElseIf cTpInsp = "5"
   oPrn:Say(li+40,1200,"TIPO Q",oFont09,100)
Endif
oPrn:Say(li+40,1890,"Cond. Entrega",oFont09n,100)
If cTpFrete = "C"
   oPrn:Say(li+40,2150,"CIF",oFont09,100)
ElseIf cTpFrete = "F"
   oPrn:Say(li+40,2150,"FOB",oFont09,100)
Endif

/*oPrn:Say(li+90,080,"CCL ",oFont09n,100)
If cCCL = "N"
   oPrn:Say(li+90,345,"NÃO",oFont09,100)
Elseif cCCL = "S"
   oPrn:Say(li+90,345,"SIM",oFont09,100)
Endif
*/

oPrn:Say(li+90,080,"Tipo Entrega ",oFont09n,100)
If cTpEntr = "1"
   oPrn:Say(li+90,345,"TOTAL",oFont09,100)
Elseif cTpEntr = "2"
   oPrn:Say(li+90,345,"PARCIAL",oFont09,100)
Endif
oPrn:Say(li+90,800,"Permite Antecipação",oFont09n,100)
If cAntec = "S"
   oPrn:Say(li+90,1200,"SIM",oFont09,100)
Else
   oPrn:Say(li+90,1200,"NAO",oFont09,100)
Endif
ImpCabCx()

Return

************************
Static Function ImpCabCx
************************
li:=li+190

oPrn:Line(li,050,li,2350) // Linha antes do cabeçalho de Itens
//oPrn:Box(li,050,1830,2350) //box 3 - Itens    
//linhas verticais divisorias dos itens:
oPrn:Line(li,050,li+150,050)     // Inicio
oPrn:Line(li,140,li+150,140)     // Item-Quantidade
oPrn:Line(li,230,li+150,230)     // Quantidade-Codigo
oPrn:Line(li,470,li+150,470)   // Codigo-Descricao
oPrn:Line(li,1200,li+150,1200)   // Descricao-Valor unit.
oPrn:Line(li,1450,li+150,1450)   // Valor unit.-IPI %
oPrn:Line(li,1570,li+150,1570)   // IPI %-valor IPI
oPrn:Line(li,1770,li+150,1770)   // valor IPI-Valor Total
oPrn:Line(li,2000,li+150,2000)   // Valor Total-Data Entrega 
oPrn:Line(li,2200,li+150,2200)   // Data Entrega-Prazo
oPrn:Line(li,2350,li+150,2350)   // Final

li:=li+40
oPrn:Say(li,060 ,"ÍTEM",oFont08n,100)
oPrn:Say(li,160 ,"QTD",oFont08n,100)
oPrn:Say(li,250,"CODIGO",oFont08n,100)
oPrn:Say(li,490,"DESCRIÇÃO",oFont08n,100)
oPrn:Say(li,1220,"VALOR UNIT.",oFont08n,100)
oPrn:Say(li,1470,"%IPI",oFont08n,100)
oPrn:Say(li,1590,"VALOR IPI",oFont08n,100)
oPrn:Say(li,1790,"VALOR TOTAL",oFont08n,100)
oPrn:Say(li,2025,"ENTREGA",oFont08n,100)
oPrn:Say(li,2220,"PRAZO",oFont08n,100)
li:=li+60

oPrn:Line(li,050,li,2350) // Linha depois do cabeçalho de Itens

Return .T.

************************
Static Function ImpDet()
************************
li:=li+30

DbSelectArea("C6")
C6->(DbGotop())

DO  WHILE C6->( !Eof() )

	If  LastKey() = 286    //ALT_A
    	lEnd := .t.
	EndIf
	If  lEnd
		Exit
	Endif
			
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica se havera salto de formulario                       ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If  li > 3000
		nOrdem++
		nPag++
        oPrn:Say(li,2200,"continua...",oFont09n,100)
		oPrn:EndPage()
		oPrn:StartPage()
		ImpCabec()
	Endif

    If C6->QUANT = 0
       C6->( DBSKIP( ) )
       Loop
    Endif
	_nPIPI:=C6->B1_IPI
	_nVIPI:=0    
	ObtVIPI()        
	nPrz := Ctod(Substr(C6->C6_ENTREG,7,2)+"/"+Substr(C6->C6_ENTREG,5,2)+"/"+Substr(C6->C6_ENTREG,3,2)) - dEmissao
    oPrn:Line(li-30,050,li+60,050)     // Inicio
   	oPrn:Say(li,070 ,C6->C6_ITEM,oFont08,100)
   	oPrn:Line(li-30,140,li+60,140)     // Item-Quantidade
    oPrn:Say(li,160 ,Trans(C6->QUANT,"@E 9,999"),oFont08,100)
   	oPrn:Line(li-30,230,li+60,230)     // Quantidade-Codigo
    oPrn:Say(li,250 ,C6->C6_PRODUTO,oFont08,100)
   	oPrn:Line(li-30,470,li+60,470)   // Codigo-Descricao
   	oPrn:Say(li,490 ,C6->B1_DESC,oFont08,100)
   	oPrn:Line(li-30,1200,li+60,1200)   // Descricao-Valor unit.
    oPrn:Say(li,1430,Alltrim(Trans(C6->C6_PRCVEN,"@E 99,999.99")),oFont08,,,,1)
   	oPrn:Line(li-30,1450,li+60,1450)   // Valor unit.-IPI %
   	oPrn:Say(li,1550,Alltrim(Trans(_nPIPI,"@E 99.99")),oFont08,,,,1)
   	oPrn:Line(li-30,1570,li+60,1570)   // IPI %-valor IPI
    oPrn:Say(li,1750,Alltrim(Trans(_nVIPI,"@E 999,999.99")),oFont08,,,,1)
   	oPrn:Line(li-30,1770,li+60,1770)   // valor IPI-Valor Total
    oPrn:Say(li,1990,Alltrim(Trans(((C6->C6_PRCVEN*C6->QUANT) + _nVIPI),"@E 999,999,999.99")),oFont08,,,,1)
   	oPrn:Line(li-30,2000,li+60,2000)   // Valor Total-Data Entrega 
   	oPrn:Say(li,2025,Dtoc(Stod(C6->C6_ENTREG)),oFont08,100)
   	oPrn:Line(li-30,2200,li+60,2200)   // Data Entrega-Prazo
   	oPrn:Say(li,2220,Alltrim(Trans(nPrz,"@E 999"))+" DD",oFont08,100)
   	oPrn:Line(li-30,2350,li+60,2350)   // Final
    
    li := li + 30    
    oPrn:Say(li,250 ,"NCM "+C6->B1_POSIPI,oFont08,100)

    li := li + 30    
	oPrn:Line(li,050,li,2350) //Linha entre os Itens    

    li := li + 30
	nVlrTot+=(C6->C6_PRCVEN*C6->QUANT)
	nTotIPI+=_nVIPI

    C6->( DBSKIP( ) )

ENDDO
   
li := li - 30
Do While li < 3000
   oPrn:Line(li,050,li+90,050)     // Inicio
   oPrn:Line(li,140,li+90,140)     // Item-Quantidade
   oPrn:Line(li,230,li+90,230)     // Quantidade-Codigo
   oPrn:Line(li,470,li+90,470)   // Codigo-Descricao
   oPrn:Line(li,1200,li+90,1200)   // Descricao-Valor unit.
   oPrn:Line(li,1450,li+90,1450)   // Valor unit.-IPI %
   oPrn:Line(li,1570,li+90,1570)   // IPI %-valor IPI
   oPrn:Line(li,1770,li+90,1770)   // valor IPI-Valor Total
   oPrn:Line(li,2000,li+90,2000)   // Valor Total-Data Entrega 
   oPrn:Line(li,2200,li+90,2200)   // Data Entrega-Prazo
   oPrn:Line(li,2350,li+90,2350)   // Final
   li += 90
Enddo
oPrn:Line(li,050,li,2350) //Linha entre os Itens    

Return

*************************
Static Function ImpRodape
*************************
li+=40
oPrn:Box(li,0050,li+220,1700) // Box do OBS
// Imprime Mensagem de Observacao
li+=40
oPrn:Say(li,080  ,"ELABORADO POR: ",oFont09,100)
oPrn:Say(li,800  ,"APROVADO POR: ",oFont09,100)
li+=40•
oPrn:Say(li,080  ,"OBS.: ",oFont09,100)
oPrn:Say(li+40,080 ," "+substr(cObserv,1,80),oFont09,100)
oPrn:Say(li+80,080 ," "+substr(cObserv,81,80),oFont09,100)

oPrn:Box(li,2000,li+130,2350) // Box do Total
oPrn:Say(li,1800,"TOTAL ",oFont09n,100)
oPrn:Say(li,2300,Alltrim(Trans((nVlrTot+nTotIPI),"@E 999,999,999.99")),oFont09n,,,,1)
li+=40
oPrn:Say(li,1800,"% ICMS",oFont09n,100)
oPrn:Say(li,2300,Alltrim(Trans(Aliq,"@E 999")+" %"),oFont09n,,,,1)
li+=40
oPrn:Say(li,1800,"VAL. ICMS",oFont09n,100)    
oPrn:Say(li,2300,Alltrim(Trans((nVlrTot*Aliq/100),"@E 999,999.99")),oFont09n,,,,1) 

oPrn:EndPage()

Return

***********************
Static Function OBTVIPI
***********************
If	C6->F4_IPI <> 'N' .and. C6->F4_DESTACA <> 'N'
	If	C6->C6_PRCVEN*C6->QUANT>0      
		_nVIPI:=C6->C6_PRCVEN*C6->QUANT*_nPIPI/100   
		_nVIPI:=Noround(_nVIPI,2)
	Else
		_nVIPI:=_nPIPI:=0
	Endif
Else	
	_nVIPI:=_nPIPI:=0
Endif
Return

**************************
Static Function CriaPerg
**************************
Local _sAlias := Alias()
Local aRegs   := {}
Local i
Local j

dbSelectArea("SX1")
dbSetOrder(1)
cPerg := PADR(cPerg,10)

//Grupo/Ordem/Pergunta/Variavel/Tipo/Tamanho/Decimal/Presel/GSC/Valid/Var01/Def01/Cnt01/Var02/Def02/Cnt02/Var03/Def03/Cnt03/Var04/Def04/Cnt04/Var05/Def05/Cnt05
aAdd(aRegs,{cPerg,"01","Pedido Inicial           ","","","mv_ch1","C",6,00,0,"G","","mv_par01","","","","","","","","","","","","","","","","","","","","","","","","",""})
aAdd(aRegs,{cPerg,"02","Pedido Final             ","","","mv_ch2","C",6,00,0,"G","","mv_par02","","","","","","","","","","","","","","","","","","","","","","","","",""})
aAdd(aRegs,{cPerg,"03","Quant. Liberada ou Saldo ","","","mv_ch3","N",1,00,0,"C","","mv_par03","Quant.Liberada","","","","","Saldo","","","","","","","","","","","","","","","","","","",""})

For I:=1 to Len(aRegs)
    If !dbSeek(cPerg+aRegs[i,2])
        RecLock("SX1",.T.)
        For j:=1 to Len(aRegs[i])//FCount()
            If j <= Len(aRegs[i])
                FieldPut(j,aRegs[i,j])
            Endif
        Next
        MsUnlock()
    Endif
Next

dbSelectArea(_sAlias)

Return
