*Armando la data por módulos
clear all
set more off

global data "C:\Users\Lori\Desktop\Informalidad"
global output "C:\Users\Lori\Desktop\Informalidad\Output"

cd $data

*Selección del año
*desde el año 2007 se presenta la variable estructura sobre empleo formal o informal
*debemos correr todo el comando para que local funcione
local year 2007

use conglome vivienda hogar codperso ubigeo p204 p205 p206 p207 p208a p209 using "enaho01-`year'-200.dta", clear

rename p207 gender
rename p208a age
rename p209 est_civil
destring conglome, replace
destring vivienda, replace
destring hogar, replace
destring codperso, replace
save "mod200-`year'.dta", replace

use conglome vivienda hogar codperso p4191 p4192 p4193 p4194 using "enaho01a-`year'-400.dta", clear
* Afiliacion seguro medico SEGMED
* Se asume que un trabajador que cotiza
* seguridad social tiene por tanto algun tipo
* de contrato, recibe vacaciones, etc.
*si segmed=0 tiene seguro de salud
gen segmed = 1
replace segmed = 0 if p4191==1
replace segmed = 0 if p4192==1
replace segmed = 0 if p4193==1
replace segmed = 0 if p4194==1
drop p4191 p4192 p4193 p4194
label var segmed "No cuenta con seguro"
destring conglome, replace
destring vivienda, replace
destring hogar, replace
destring codperso, replace
save "mod400-`year'.dta", replace

use conglome vivienda hogar codperso fac500a i513t i518 i524d1 i530a i538d1 i541a ocu500 p505 p506 p507 p510 p510a p510b ///
p512a p512b ocupinf using "enaho01a-`year'-500.dta", clear
*ocupinf
rename i524d1 i524e1
rename i538d1 i538e1

**  Clasificacion internacional de la
*   situacion en el empleo (cise).
*   1) Cuenta propia.
*   2) Empleadores.
*   3) Trabajador familiar auxiliar.
*   4) Empleados.

gen		cise = 2 if p507==1
replace cise = 1 if p507==2
replace cise = 4 if p507==3
replace cise = 4 if p507==4
replace cise = 3 if p507==5
replace cise = 4 if p507==6
replace cise = 5 if p507==7

rename fac500a pw
*agregue cise =5
destring conglome, replace
destring vivienda, replace
destring hogar, replace
destring codperso, replace
save "mod500-`year'.dta", replace



*Uniendo bases
use "mod200-`year'.dta", clear
merge 1:1 conglome vivienda hogar codperso using "mod400-`year'.dta"
drop _merge
merge 1:1 conglome vivienda hogar codperso using "mod500-`year'.dta"
keep if _merge==3
drop _merge

* CLASIFICANDO EN SECTOR FORMAL E INFORMAL (sec_siu).
*    1) SECTOR INFORMAL.
*       CUENTA PROPIA Y EMPLEADORES (p507=1 o p507=2).
*         Se consideran con empleo en el sector informal los que tienen
*         negocios o empresas que no se encuentran registradas como persona
*         juridica (P510a = 2) y que no llevan las cuentas por medios de
*         libros exigidos por la SUNAT o sistema de contabilidad (P510b = 2)
*         y que tienen 5 o menos personas ocupadas (P512 < 6)
*
*       Trabajador Familiar Auxiliar (P507 = 5).
*         Se consideran con empleo en el sector informal los que trabajan en
*         empresas o negocios con 5 o menos personas ocupadas (P512 < 6)
*
*       Asalariados (P507 = 3, 4, 7)
*         Se consideran con empleo en el sector informal los que no son
*         trabajadores domesticos  (P507 = 6) y que trabajan para una empresa
*         o patrono privado, (P510 = 5, 6),  (i) que no estan registrados como
*         persona juridica (P510a = 2) (ii) que no llevan las cuentas por
*         medios de libros exigidos por la SUNAT o sistema de contabilidad
*         (P510b = 2)  y (iii) que tienen 5 o menos personas ocupadas (P512 < 6)
*
*    2) SECTOR DE HOGARES.
*       Incluye a todos los trabajadores del hogar (P507 = 6).
*
*    3) SECTOR FORMAL.
*       Empleados del sector publico.
*       Todos los ocupados no clasificados como del sector informal, ni del
*       sector de hogares.

*1 formal
*2 informal
gen 	sec_siu = 1
replace sec_siu = 1 if ((p507==3 | p507==4 ) & (p510==1 | p510==2 | p510==3))
replace sec_siu = 2 if ((p507==1 | p507==2) & (p510a==2) & p510b==2 & p512a==1 & (p512b>=1 & p512b<=5))
replace sec_siu = 2 if ((p507==5 | p510==5) & p512a==1 & (p512b>=1 & p512b<=5))
replace sec_siu = 2 if ((p507==3 | p507==4 | p507==7) & (p510==5 | p510==6) & (p510a==2) & p510b==2 & p512a==1 ///
& (p512b>=1 & p512b<=5))
*cambios:
*sacar a otros p507=7 de formales
*incluir p510a1=3, no esta registrado en la sunat  

** Empleo Informal:
* Se asume que un trabajador que cotiza
* seguridad social tiene por tanto algun tipo
* de contrato, recibe vacaciones, etc.

* Basado en la tenencia de seguro medico,
* se codifica cada trabajador como formal
* o informal.
* Observar que los numeros impares son
* informales y los pares formales.

* (2)
* (i)   trabajadores por cuenta propia dueños de sus
*       propias empresas del sector informal.
* (ii)  empleadores dueños de sus propias empresas
*       del sector informal.
* (iii) trabajadores familiares auxiliares independiemtente
*       de si trabajan en empresas del sector formal o informal.
* (5)   asalariados que no cotizan seguridad social.

gen 	emp_siu = 1 if (cise==1 & sec_siu==2)
replace emp_siu = 2 if (cise==1 & sec_siu==1)
replace emp_siu = 3 if (cise==2 & sec_siu==2)
replace emp_siu = 4 if (cise==2 & sec_siu==1)
replace emp_siu = 5 if (cise==3 & cise==5) 
replace emp_siu = 7 if (cise==4 & segmed==1)
replace emp_siu = 8 if (cise==4 & segmed==0)
*agregue cise 5 a emp_siu=5
* poblacion ocupada no residente, .
*0 no pea, desocupado
*pea:ocupado
gen ocupres =((p204 == 1 & p205 == 2) | (p204 == 2 & p206 == 1)) & ocu500 == 1
label variable segmed  "Afiliado a seguro medico por trabajo"
label variable cise    "Empleos segun situacion en el empleo"
label variable sec_siu "Tipo de unidad de produccion"
label variable emp_siu "Empleo Formal e Informal"
drop p204 p205 p206 p510 p510a p510b p512a p512b

* Indicador de Informalidad:
gen ocupinfp =  0 if (emp_siu==2 | emp_siu==4 |emp_siu==8)
replace ocupinfp = 1 if (emp_siu==1 | emp_siu==3 | emp_siu==5 | emp_siu==7) 
*replace ocupinfp = . if ocupres==0
label variable ocupinfp "Condicion de empleo-replica"
*no le podemos poner label porq se pone valor 0 y 1 automatico, nosostros no lo hemos asiganado
*label define ocupinfp 0 "empleo_formal" 1 "empleo_informal"
* o es empleo formal y 1 empleo informal
*drop ocupres
cd $output
save "basefinal-`year'.dta", replace
*tablas para cada año
tabout ocupinf ocupinfp p507 using tabresumen_`year'.xls, h3(nil) 

*correlación
replace ocupinf=0 if ocupinf==2
pwcorr ocupinfp ocupinf



