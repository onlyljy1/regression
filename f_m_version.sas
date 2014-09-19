/*********************************************************/
/**********��һ���֣��ع�,Ŀ���ǵõ��õ����ֵy_fit*********/
/*********************************************************/

libname datapool 'C:\Users\xun\Desktop\liu\data';

data Retdata;
set Datapool.demean_ret;
coid=abs(coid);
if industry~=.;
run;

proc sort data=retdata;
by date coid;
run;

 %let depvar1 = y_factor;
 %let indvar1 = trd_f1_l trd_f2_l trd_f3_l trd_f4_l trd_f5_l ;

%include 'C:\Users\xun\Desktop\liu\fmreg_macro.sas';
%FM_piece (INSET=retdata ,OUTSET=FMresult_comp,DATEVAR=date,DEPVAR=&depvar1, 
INDVARS=&indvar1, LAG=22);

/*�ع�*/
 %let depvar = y_factor;
 %let indvar = trd_f1_l trd_f2_l trd_f3_l trd_f4_l trd_f5_l;
 %let input = retdata;

proc reg data=&input outest=est_beta_rev noprint TABLEOUT;
by date;
model &depvar = &indvar;
run;
quit;

/*ϵ��coef�ͱ�׼��stdd*/
data coef;
set Est_beta_rev;
if _TYPE_ = 'PARMS';
drop _MODEL_ _TYPE_ _DEPVAR_ _RMSE_ y_factor;
run;

data coef;
set coef;
rename Intercept=beta_0 trd_f1_l=beta_1 trd_f2_l=beta_2 trd_f3_l=beta_3 
trd_f4_l=beta_4 trd_f5_l=beta_5 ;
run; 

/*��ʱ�ò���stdd
data stdd;
set Est_beta_rev;
if _TYPE_ = 'STDERR';
drop _MODEL_ _TYPE_ _DEPVAR_ _RMSE_ y_factor;
run;

data stdd;
set stdd;
rename Intercept=std_0 trd_f1_l=std_1 trd_f2_l=std_2 trd_f3_l=std_3 trd_f4_l=std_4 trd_f5_l=std_5;
run; 
*/

PROC EXPAND data= coef OUT= coef_temp METHOD=NONE;   
      convert beta_0=beta_0_ave /transform=(movave 480);
      convert beta_1=beta_1_ave /transform=(movave 480);
      convert beta_2=beta_2_ave /transform=(movave 480);
      convert beta_3=beta_3_ave /transform=(movave 480);
      convert beta_4=beta_4_ave /transform=(movave 480);
	  convert beta_5=beta_5_ave /transform=(movave 480);
RUN;

data coef_temp;
set coef_temp;
if time>=480;
drop time;
run;

/*ƴ��*/
data trd_daily_beta_rev; 
merge &input(in=in1 keep= coid date industry y_factor trd_f1_l trd_f2_l
trd_f3_l trd_f4_l trd_f5_l trd_f1 trd_f2 trd_f3 trd_f4 trd_f5) 
coef_temp (in=in2 keep= date beta_0_ave beta_1_ave beta_2_ave beta_3_ave
beta_4_ave beta_5_ave);
by date;
if in1=1;
if in2=1;
run;

/*���Դ�shrink*/
data trd_daily_beta_rev; 
set trd_daily_beta_rev; 
beta_1_ave=beta_1_ave*7/8;
beta_2_ave=beta_2_ave*5/8;
beta_3_ave=beta_3_ave*3/8;
beta_4_ave=beta_4_ave*5/8;
beta_5_ave=beta_5_ave*3/8;
run;


/*�������ֵy_fit*/
data trd_daily_beta_rev;
set trd_daily_beta_rev;
y_fit=beta_1_ave*trd_f1+beta_2_ave*trd_f2+beta_3_ave*trd_f3+beta_4_ave*trd_f4+
beta_5_ave*trd_f5;
run;


data trd_daily_beta_rev;
set trd_daily_beta_rev;
if y_fit=. then delete;
run;
/*�����ʱҲ����
PROC EXPAND data= stdd OUT= stdd_temp METHOD=NONE;     
      convert std_0=std_0_ave /transform=(movave 480);
      convert std_1=std_1_ave /transform=(movave 480);
      convert std_2=std_2_ave /transform=(movave 480);
      convert std_3=std_3_ave /transform=(movave 480);
      convert std_4=std_4_ave /transform=(movave 480);
      convert std_5=std_5_ave /transform=(movave 480);
RUN;
*/



/*********************************************************/
/*********************�ڶ����֣�����return*****************/
/*********************************************************/

data Dailyret; 
set Datapool.Dailyret;
keep date id ret;
run;

data dailyret;
set dailyret;
id=abs(id);
run;

data industry; 
set Datapool.Swic_finance_detail;
keep id codes;
run;

proc sort data=dailyret;
by id;run;

proc sort data=industry;
by id; run;

data dailyret;
merge dailyret industry;
by id;
run;

data dailyret;
set dailyret;
if codes~=.;
run;

/*׼��������ҵÿ��ľ�ֵ*/
proc sort data=dailyret;
by date codes;run;

proc means data=dailyret noprint;
var ret;
output out=dailyret_1 mean(ret)=indave;
by date codes;
run;

data dailyret;
merge dailyret dailyret_1(keep=date codes indave);
by date codes;
run;

/*ret�� demeanret �ֱ���demean֮ǰ�ĺ�demean֮���*/
data dailyret;
set dailyret;
demeanret=ret-indave;
run;

/*true ret������ԭ����ÿ�ճֲֹ�Ʊ��Ŀ�ľ���Ҫ�ҵ����ǵ���ʵ�����y_fit���бȽ�*/
data true_ret;
set retdata;
keep coid date;
run;

data true_ret;
set true_ret;
coid=abs(coid);
run;

data dailyret;
set dailyret;
rename id=coid;
run;

proc sort data=dailyret;
by date coid ;
run;

data true_ret;
merge true_ret(in=in1) dailyret(keep=date coid ret demeanret);
by date coid ;
if in1=1;
run;

/*���������ǰ�������ͨ��moving sumת��Ϊ������*/
/*demean��ret*/

proc sort data=true_ret;
by coid date;
run;

PROC EXPAND data= true_ret OUT= weekly_ret METHOD=NONE;   
      convert ret=ret_weekly /transformout = (reverse movsum 5 reverse);
	  convert demeanret=demeanret_weekly /transformout = (reverse movsum 5 reverse);
	  by coid;
RUN;

/*ÿһ�������ĸ���׼ȷ�����ɾ��*/
proc sort data=weekly_ret;
by coid descending time ;
run;

data weekly_ret;
retain temp 0;
set weekly_ret;
by coid;
if first.coid=1 then temp=0;
temp=temp+1;
run;

data weekly_ret;
set weekly_ret;
if temp<=4 then delete;
run;

proc sort data=weekly_ret;
by coid date ;
run;

data weekly_ret;
set weekly_ret;
drop temp;
run;

/*��������ʱ��lagһ��*/
data weekly_ret;
set weekly_ret;
date_l=lag(date);
FORMAT date_l MMDDYY10.;
by coid;
run;

/*ÿ��id�ĵ�һ�ڶ�ֱ��ɾȥ����Ϊǰһ���ǿյ�*/
data weekly_ret;
set weekly_ret;
if time~=0;
run;

/*********************************************************/
/*�������֣�������ʷ��ֵ���кͼ������е�cross-sectional mean*/
/*********************************************************/

PROC EXPAND data= weekly_ret OUT= weekly_ret_avg METHOD=NONE;     
      convert demeanret_weekly=demeanret_weekly_accu /transformout=( cusum );
	  by coid;
RUN;

data weekly_ret_avg;
set weekly_ret_avg;
demeanret_weekly_accave=demeanret_weekly_accu/(time+1);
drop demeanret_weekly_accu;
run;

PROC EXPAND data= weekly_ret_avg OUT= weekly_ret_avg METHOD=NONE;     
      convert demeanret_weekly=demeanret_weekly_movingave /transform=(movave 480);
	  by coid;
RUN;

proc datasets library=work nolist;
modify weekly_ret_avg;
attrib _all_ label="";
quit;

data weekly_ret_avg;
set weekly_ret_avg;
if time>=480;
run;

/*����ʷ��ֵ��ȡ������lead�����Ա��������ʷ��ֵ����ֵ�ص������*/
data hist_ave;
set weekly_ret_avg;
keep coid date_l demeanret_weekly_movingave demeanret_weekly_accave;
run;

proc expand data=hist_ave out=hist_ave method=none;
var date_l;
convert date_l=datelead / transform=( lead 4 );
by coid;
run;

data hist_ave;
set hist_ave;
if datelead~=.;
run;

data weekly_ret_avg;
set weekly_ret_avg;
drop date demeanret_weekly_movingave demeanret_weekly_accave;
run;

/*�Ȱ���ʷ��moving average��accumulated average merge��ȥ*/
proc sql;
create table r_rho as select
a.*,
b.*
from hist_ave as a
join
weekly_ret_avg as b
on a.coid=b.coid
and a.datelead=b.date_l
order by a.coid, a.date_l;
quit;

/*��������Y-fit merge����*/
proc sql;
create table r_rho as select
a.*,
b.y_fit
from r_rho as a
join
Trd_daily_beta_rev as b
on a.coid=b.coid
and a.date_l=b.date
order by a.coid, a.date_l;
quit;

data r_rho;
set r_rho;
drop time date_l;
run;

/*�������Ǽ���cross-sectional average*/

proc sort data=r_rho;
by datelead coid;
run;

proc means data=r_rho noprint;
var demeanret_weekly_movingave demeanret_weekly_accave demeanret_weekly y_fit;
output out=temp mean(demeanret_weekly_movingave demeanret_weekly_accave
demeanret_weekly y_fit)=demeanret_weekly_moving_crosec 
demeanret_weekly_accave_crosec demeanret_weekly_crosec y_fit_crosec;
by datelead;
run;

/*note: demeanret_weekly_moving_crosecӦ�ý�demeanret_weekly_movingave_crosec�ģ�
������Ϊ����̫���������ˡ���*/
data r_rho;
merge r_rho temp(keep=datelead demeanret_weekly_moving_crosec 
demeanret_weekly_accave_crosec demeanret_weekly_crosec y_fit_crosec);
by datelead;
run;

proc sort data=r_rho;
by coid datelead;
run;
/*���ϼ����r_rho������Ҫ���������������Ҫ��һ�����У���ʱ��datelead(Ҫ�õ�ʱ��),��ʱ������Ӧ��
��һ�ڵ���ʵֵ��Ԥ��ֵdemeanret_weekly y_fit��Ȼ���Ǹ�ʱ��ǰ���ڵ���ʷ��ֵdemeanret_weekly_movingave 
demeanret_weekly_accave���Լ���������ÿ�յ�cross-sectional�ľ�ֵ*/




/*���ڼ���oos variance r sq��12���㷨������Ҳ�����ˡ��о���Ҳ����ƴ��**/
/******************************************************************/
/**************���Ĳ��֣�����oos variance r sq *********************/
/******************************************************************/



/* 1�����ǰ��ն�stock����ȡ��ֵ������ģ���������Ҫ����date��ȡ��ֵ��
�Լ�ֱ��pooling�������*/




/*�Ȱ��յ�һ�ַ�����һ�£���һ�ַ��������ֶ���cross-sectional �ľ�ֵ�۵�*/
/*����moving average����ʷ����bar��r���µ�oos r sq*/
data oos_rsq_1;
set r_rho;
keep coid demeanret_weekly_movingave demeanret_weekly_moving_crosec 
demeanret_weekly demeanret_weekly_crosec datelead y_fit y_fit_crosec;
run;

data oos_rsq_1;
set oos_rsq_1;
numerator=(demeanret_weekly-demeanret_weekly_crosec-y_fit+y_fit_crosec)**2;
denominator=(demeanret_weekly-demeanret_weekly_crosec-demeanret_weekly_movingave+
demeanret_weekly_moving_crosec)**2;
run;

proc means data=oos_rsq_1 noprint;
var numerator denominator;
output out=cal sum(numerator denominator)=sumnumerator sumdenominator;
by coid;
run;

data cal;
set cal;
oos_rsq_1=1-sumnumerator/sumdenominator;
run;

/*cal_1�еľ��ǲ�����ʷmoving average��Ϊ��ֵʱ�Ľ��*/
proc means data=cal noprint;
var oos_rsq_1;
output out=cal_1 mean(oos_rsq_1)=oos_rsq_1;
run;
/******************************************************/
/*�����������ۼƾ�ֵ�µ�oos r sq*/
data oos_rsq_2;
set r_rho;
keep coid demeanret_weekly_accave demeanret_weekly_accave_crosec 
demeanret_weekly demeanret_weekly_crosec datelead y_fit y_fit_crosec;
run;

data oos_rsq_2;
set oos_rsq_2;
numerator=(demeanret_weekly-demeanret_weekly_crosec-y_fit+y_fit_crosec)**2;
denominator=(demeanret_weekly-demeanret_weekly_crosec-demeanret_weekly_accave
+demeanret_weekly_accave_crosec)**2;
run;

proc means data=oos_rsq_2 noprint;
var numerator denominator;
output out=cal_2 sum(numerator denominator)=sumnumerator sumdenominator;
by coid;
run;

data cal_2;
set cal_2;
oos_rsq_2=1-sumnumerator/sumdenominator;
run;

/*cal_3�еľ��ǲ�����ʷaccumulated average��Ϊ��ֵʱ�Ľ��*/
proc means data=cal_2 noprint;
var oos_rsq_2;
output out=cal_3 mean(oos_rsq_2)=oos_rsq_2;
run;
/*******************************************************************/
/*�ٰ��յڶ��ַ�����һ�£�����ֱ����demean���е�variance�ͺ�***********/
/*******����moving average����ʷ����bar��r���µ�oos r sq*************/
/*����moving average����ʷ����bar��r���µ�oos r sq*/
data oos_rsq_3;
set r_rho;
keep coid demeanret_weekly datelead y_fit demeanret_weekly_movingave;
run;

data oos_rsq_3;
set oos_rsq_3;
numerator=(demeanret_weekly-y_fit);
denominator=(demeanret_weekly-demeanret_weekly_movingave);
run;

proc means data=oos_rsq_3 noprint;
var numerator denominator;
output out=cal_4 var(numerator denominator)=varnumerator vardenominator;
by coid;
run;

data cal_4;
set cal_4;
oos_rsq_3=1-varnumerator/vardenominator;
run;

/*cal_5�еľ��ǲ�����ʷmoving average��Ϊ��ֵʱ�Ľ��*/
proc means data=cal_4 noprint;
var oos_rsq_3;
output out=cal_5 mean(oos_rsq_3)=oos_rsq_3;
run;

/******************************************************/
/*�����������ۼƾ�ֵ�µ�oos r sq*/
data oos_rsq_4;
set r_rho;
keep coid demeanret_weekly datelead y_fit demeanret_weekly_accave;
run;

data oos_rsq_4;
set oos_rsq_4;
numerator=(demeanret_weekly-y_fit);
denominator=(demeanret_weekly-demeanret_weekly_accave);
run;

proc means data=oos_rsq_4 noprint;
var numerator denominator;
output out=cal_6 var(numerator denominator)=varnumerator vardenominator;
by coid;
run;

data cal_6;
set cal_6;
oos_rsq_4=1-varnumerator/vardenominator;
run;

/*cal_7�еľ��ǲ�����ʷaccumulated average��Ϊ��ֵʱ�Ľ��*/
proc means data=cal_6 noprint;
var oos_rsq_4;
output out=cal_7 mean(oos_rsq_4)=oos_rsq_4;
run;




/***************************/
/*2�������Ƕ�date����avg�Ľ��*/





/*�Ȱ��յ�һ�ַ�����һ�£���һ�ַ��������ֶ���cross-sectional �ľ�ֵ�۵�*/
/*����moving average����ʷ����bar��r���µ�oos r sq*/
data oos_rsq_1_d;
set r_rho;
keep coid demeanret_weekly_movingave demeanret_weekly_moving_crosec 
demeanret_weekly demeanret_weekly_crosec datelead y_fit y_fit_crosec;
run;

data oos_rsq_1_d;
set oos_rsq_1_d;
numerator=(demeanret_weekly-demeanret_weekly_crosec-y_fit+y_fit_crosec)**2;
denominator=(demeanret_weekly-demeanret_weekly_crosec-demeanret_weekly_movingave+
demeanret_weekly_moving_crosec)**2;
run;

proc sort data=oos_rsq_1_d;
by datelead coid;
run;

proc means data=oos_rsq_1_d noprint;
var numerator denominator;
output out=cal_d sum(numerator denominator)=sumnumerator sumdenominator;
by datelead;
run;

data cal_d;
set cal_d;
oos_rsq_1_d=1-sumnumerator/sumdenominator;
run;

/*cal_1_d�еľ��ǲ�����ʷmoving average��Ϊ��ֵʱ�Ľ��*/
proc means data=cal_d noprint;
var oos_rsq_1_d;
output out=cal_1_d mean(oos_rsq_1_d)=oos_rsq_1_d;
run;
/******************************************************/
/*�����������ۼƾ�ֵ�µ�oos r sq*/
data oos_rsq_2_d;
set r_rho;
keep coid demeanret_weekly_accave demeanret_weekly_accave_crosec 
demeanret_weekly demeanret_weekly_crosec datelead y_fit y_fit_crosec;
run;

data oos_rsq_2_d;
set oos_rsq_2_d;
numerator=(demeanret_weekly-demeanret_weekly_crosec-y_fit+y_fit_crosec)**2;
denominator=(demeanret_weekly-demeanret_weekly_crosec-demeanret_weekly_accave
+demeanret_weekly_accave_crosec)**2;
run;

proc sort data=oos_rsq_2_d;
by datelead coid;
run;

proc means data=oos_rsq_2_d noprint;
var numerator denominator;
output out=cal_2_d sum(numerator denominator)=sumnumerator sumdenominator;
by datelead;
run;

data cal_2_d;
set cal_2_d;
oos_rsq_2_d=1-sumnumerator/sumdenominator;
run;

/*cal_3_d�еľ��ǲ�����ʷaccumulated average��Ϊ��ֵʱ�Ľ��*/
proc means data=cal_2_d noprint;
var oos_rsq_2_d;
output out=cal_3_d mean(oos_rsq_2_d)=oos_rsq_2_d;
run;
/*******************************************************************/
/*�ٰ��յڶ��ַ�����һ�£�����ֱ����demean���е�variance�ͺ�***********/
/*******����moving average����ʷ����bar��r���µ�oos r sq*************/
/*����moving average����ʷ����bar��r���µ�oos r sq*/
data oos_rsq_3_d;
set r_rho;
keep coid demeanret_weekly datelead y_fit demeanret_weekly_movingave;
run;

data oos_rsq_3_d;
set oos_rsq_3_d;
numerator=(demeanret_weekly-y_fit);
denominator=(demeanret_weekly-demeanret_weekly_movingave);
run;

proc sort data=oos_rsq_3_d;
by datelead coid;
run;

proc means data=oos_rsq_3_d noprint;
var numerator denominator;
output out=cal_4_d var(numerator denominator)=varnumerator vardenominator;
by datelead;
run;

data cal_4_d;
set cal_4_d;
oos_rsq_3_d=1-varnumerator/vardenominator;
run;

/*cal_5_d�еľ��ǲ�����ʷmoving average��Ϊ��ֵʱ�Ľ��*/
proc means data=cal_4_d noprint;
var oos_rsq_3_d;
output out=cal_5_d mean(oos_rsq_3_d)=oos_rsq_3_d;
run;

/******************************************************/
/*�����������ۼƾ�ֵ�µ�oos r sq*/
data oos_rsq_4_d;
set r_rho;
keep coid demeanret_weekly datelead y_fit demeanret_weekly_accave;
run;

data oos_rsq_4_d;
set oos_rsq_4_d;
numerator=(demeanret_weekly-y_fit);
denominator=(demeanret_weekly-demeanret_weekly_accave);
run;

proc sort data=oos_rsq_4_d;
by datelead coid;
run;

proc means data=oos_rsq_4_d noprint;
var numerator denominator;
output out=cal_6_d var(numerator denominator)=varnumerator vardenominator;
by datelead;
run;

data cal_6_d;
set cal_6_d;
oos_rsq_4_d=1-varnumerator/vardenominator;
run;

/*cal_7_d�еľ��ǲ�����ʷaccumulated average��Ϊ��ֵʱ�Ľ��*/
proc means data=cal_6_d noprint;
var oos_rsq_4_d;
output out=cal_7_d mean(oos_rsq_4_d)=oos_rsq_4_d;
run;




/**********************/
/*������Ӧ����pooling��*/





/*�Ȱ��յ�һ�ַ�����һ�£���һ�ַ��������ֶ���cross-sectional �ľ�ֵ�۵�*/
/*����moving average����ʷ����bar��r���µ�oos r sq*/
data oos_rsq_1_p;
set r_rho;
keep coid demeanret_weekly_movingave demeanret_weekly_moving_crosec 
demeanret_weekly demeanret_weekly_crosec datelead y_fit y_fit_crosec;
run;

data oos_rsq_1_p;
set oos_rsq_1_p;
numerator=(demeanret_weekly-demeanret_weekly_crosec-y_fit+y_fit_crosec)**2;
denominator=(demeanret_weekly-demeanret_weekly_crosec-demeanret_weekly_movingave+
demeanret_weekly_moving_crosec)**2;
run;

proc means data=oos_rsq_1_p noprint;
var numerator denominator;
output out=cal_p sum(numerator denominator)=sumnumerator sumdenominator;
run;

data cal_p;
set cal_p;
oos_rsq_1_p=1-sumnumerator/sumdenominator;
run;

/******************************************************/
/*�����������ۼƾ�ֵ�µ�oos r sq*/
data oos_rsq_2_p;
set r_rho;
keep coid demeanret_weekly_accave demeanret_weekly_accave_crosec 
demeanret_weekly demeanret_weekly_crosec datelead y_fit y_fit_crosec;
run;

data oos_rsq_2_p;
set oos_rsq_2_p;
numerator=(demeanret_weekly-demeanret_weekly_crosec-y_fit+y_fit_crosec)**2;
denominator=(demeanret_weekly-demeanret_weekly_crosec-demeanret_weekly_accave
+demeanret_weekly_accave_crosec)**2;
run;

proc means data=oos_rsq_2_p noprint;
var numerator denominator;
output out=cal_2_p sum(numerator denominator)=sumnumerator sumdenominator;
run;

data cal_2_p;
set cal_2_p;
oos_rsq_2_p=1-sumnumerator/sumdenominator;
run;

/*******************************************************************/
/*�ٰ��յڶ��ַ�����һ�£�����ֱ����demean���е�variance�ͺ�***********/
/*******����moving average����ʷ����bar��r���µ�oos r sq*************/
/*����moving average����ʷ����bar��r���µ�oos r sq*/
data oos_rsq_3_p;
set r_rho;
keep coid demeanret_weekly datelead y_fit demeanret_weekly_movingave;
run;

data oos_rsq_3_p;
set oos_rsq_3_p;
numerator=(demeanret_weekly-y_fit);
denominator=(demeanret_weekly-demeanret_weekly_movingave);
run;

proc means data=oos_rsq_3_p noprint;
var numerator denominator;
output out=cal_4_p var(numerator denominator)=varnumerator vardenominator;
run;

data cal_4_p;
set cal_4_p;
oos_rsq_3_p=1-varnumerator/vardenominator;
run;

/******************************************************/
/*�����������ۼƾ�ֵ�µ�oos r sq*/
data oos_rsq_4_p;
set r_rho;
keep coid demeanret_weekly datelead y_fit demeanret_weekly_accave;
run;

data oos_rsq_4_p;
set oos_rsq_4_p;
numerator=(demeanret_weekly-y_fit);
denominator=(demeanret_weekly-demeanret_weekly_accave);
run;

proc means data=oos_rsq_4_p noprint;
var numerator denominator;
output out=cal_6_p var(numerator denominator)=varnumerator vardenominator;
run;

data cal_6_p;
set cal_6_p;
oos_rsq_4_p=1-varnumerator/vardenominator;
run;




/******************************************************************/
/**************���岿�֣�����subsample1��oos r sq*******************/
/******************************************************************/

/*�ȷֳ���subsample*/

proc sort data=r_rho;
by datelead coid;
run;

proc rank data=r_rho out=rank_1;
var y_fit;
ranks rank_y_fit;
by datelead;
run;

proc means data=rank_1 noprint;
var rank_y_fit;
output out=temp_1 max(rank_y_fit)=maxrank;
by datelead;
run;

data rank_1;
merge rank_1 temp_1;
by datelead;
run;
/****************/
/****************/
/*��һ��subsample*/
/****************/
/****************/
data subsample_1;
set rank_1;
if rank_y_fit>=(maxrank*4/5);
drop _TYPE_ _FREQ_;
run;

proc sort data=subsample_1;
by coid;
run;

/*�Ȱ��յ�һ�ַ�����һ��*/
/*����moving average����ʷ����bar��r���µ�oos r sq*/
data oos_rsq_5;
set subsample_1;
keep coid demeanret_weekly_movingave demeanret_weekly_moving_crosec 
demeanret_weekly demeanret_weekly_crosec datelead y_fit y_fit_crosec;
run;

data oos_rsq_5;
set oos_rsq_5;
numerator=(demeanret_weekly-demeanret_weekly_crosec-y_fit+y_fit_crosec)**2;
denominator=(demeanret_weekly-demeanret_weekly_crosec-demeanret_weekly_movingave+
demeanret_weekly_moving_crosec)**2;
run;

proc means data=oos_rsq_5 noprint;
var numerator denominator;
output out=cal_8 sum(numerator denominator)=sumnumerator sumdenominator;
by coid;
run;

data cal_8;
set cal_8;
oos_rsq_5=1-sumnumerator/sumdenominator;
run;

/*cal_9�еľ��ǲ�����ʷmoving average��Ϊ��ֵʱ�Ľ��*/
proc means data=cal_8 noprint;
var oos_rsq_5;
output out=cal_9 mean(oos_rsq_5)=oos_rsq_5;
run;
/******************************************************/
/*�����������ۼƾ�ֵ�µ�oos r sq*/
data oos_rsq_6;
set subsample_1;
keep coid demeanret_weekly_accave demeanret_weekly_accave_crosec 
demeanret_weekly demeanret_weekly_crosec datelead y_fit y_fit_crosec;
run;

data oos_rsq_6;
set oos_rsq_6;
numerator=(demeanret_weekly-demeanret_weekly_crosec-y_fit+y_fit_crosec)**2;
denominator=(demeanret_weekly-demeanret_weekly_crosec-demeanret_weekly_accave
+demeanret_weekly_accave_crosec)**2;
run;

proc means data=oos_rsq_6 noprint;
var numerator denominator;
output out=cal_10 sum(numerator denominator)=sumnumerator sumdenominator;
by coid;
run;

data cal_10;
set cal_10;
oos_rsq_6=1-sumnumerator/sumdenominator;
run;

/*cal_11�еľ��ǲ�����ʷaccumulated average��Ϊ��ֵʱ�Ľ��*/
proc means data=cal_10 noprint;
var oos_rsq_6;
output out=cal_11 mean(oos_rsq_6)=oos_rsq_6;
run;

/*******************************************************************/
/*�ٰ��յڶ��ַ�����һ�£�����ֱ����demean���е�variance�ͺ�***********/
/********����moving average����ʷ����bar��r���µ�oos r sq*************/

/*����moving average����ʷ����bar��r���µ�oos r sq*/
data oos_rsq_7;
set subsample_1;
keep coid demeanret_weekly datelead y_fit demeanret_weekly_movingave;
run;

data oos_rsq_7;
set oos_rsq_7;
numerator=(demeanret_weekly-y_fit);
denominator=(demeanret_weekly-demeanret_weekly_movingave);
run;

proc means data=oos_rsq_7 noprint;
var numerator denominator;
output out=cal_12 var(numerator denominator)=varnumerator vardenominator;
by coid;
run;

data cal_12;
set cal_12;
oos_rsq_7=1-varnumerator/vardenominator;
run;

/*cal_13�еľ��ǲ�����ʷmoving average��Ϊ��ֵʱ�Ľ��*/
proc means data=cal_12 noprint;
var oos_rsq_7;
output out=cal_13 mean(oos_rsq_7)=oos_rsq_7;
run;

/******************************************************/
/*�����������ۼƾ�ֵ�µ�oos r sq*/
data oos_rsq_8;
set subsample_1;
keep coid demeanret_weekly datelead y_fit demeanret_weekly_accave;
run;

data oos_rsq_8;
set oos_rsq_8;
numerator=(demeanret_weekly-y_fit);
denominator=(demeanret_weekly-demeanret_weekly_accave);
run;

proc means data=oos_rsq_8 noprint;
var numerator denominator;
output out=cal_14 var(numerator denominator)=varnumerator vardenominator;
by coid;
run;

data cal_14;
set cal_14;
oos_rsq_8=1-varnumerator/vardenominator;
run;

/*cal_15�еľ��ǲ�����ʷaccumulated average��Ϊ��ֵʱ�Ľ��*/
proc means data=cal_14 noprint;
var oos_rsq_8;
output out=cal_15 mean(oos_rsq_8)=oos_rsq_8;
run;



/*********************************/
/*�������Ǽ����dateȡaverage�Ľ��*/




/*�Ȱ��յ�һ�ַ�����һ��*/
/*����moving average����ʷ����bar��r���µ�oos r sq*/
data oos_rsq_5_d;
set subsample_1;
keep coid demeanret_weekly_movingave demeanret_weekly_moving_crosec 
demeanret_weekly demeanret_weekly_crosec datelead y_fit y_fit_crosec;
run;

data oos_rsq_5_d;
set oos_rsq_5_d;
numerator=(demeanret_weekly-demeanret_weekly_crosec-y_fit+y_fit_crosec)**2;
denominator=(demeanret_weekly-demeanret_weekly_crosec-demeanret_weekly_movingave+
demeanret_weekly_moving_crosec)**2;
run;

proc sort data=oos_rsq_5_d;
by datelead coid;
run;

proc means data=oos_rsq_5_d noprint;
var numerator denominator;
output out=cal_8_d sum(numerator denominator)=sumnumerator sumdenominator;
by datelead;
run;

data cal_8_d;
set cal_8_d;
oos_rsq_5_d=1-sumnumerator/sumdenominator;
run;

/*cal_9_d�еľ��ǲ�����ʷmoving average��Ϊ��ֵʱ�Ľ��*/
proc means data=cal_8_d noprint;
var oos_rsq_5_d;
output out=cal_9_d mean(oos_rsq_5_d)=oos_rsq_5_d;
run;
/******************************************************/
/*�����������ۼƾ�ֵ�µ�oos r sq*/
data oos_rsq_6_d;
set subsample_1;
keep coid demeanret_weekly_accave demeanret_weekly_accave_crosec 
demeanret_weekly demeanret_weekly_crosec datelead y_fit y_fit_crosec;
run;

data oos_rsq_6_d;
set oos_rsq_6_d;
numerator=(demeanret_weekly-demeanret_weekly_crosec-y_fit+y_fit_crosec)**2;
denominator=(demeanret_weekly-demeanret_weekly_crosec-demeanret_weekly_accave
+demeanret_weekly_accave_crosec)**2;
run;

proc sort data=oos_rsq_6_d;
by datelead coid;
run;

proc means data=oos_rsq_6_d noprint;
var numerator denominator;
output out=cal_10_d sum(numerator denominator)=sumnumerator sumdenominator;
by datelead;
run;

data cal_10_d;
set cal_10_d;
oos_rsq_6_d=1-sumnumerator/sumdenominator;
run;

/*cal_11_d�еľ��ǲ�����ʷaccumulated average��Ϊ��ֵʱ�Ľ��*/
proc means data=cal_10_d noprint;
var oos_rsq_6_d;
output out=cal_11_d mean(oos_rsq_6_d)=oos_rsq_6_d;
run;

/*******************************************************************/
/*�ٰ��յڶ��ַ�����һ�£�����ֱ����demean���е�variance�ͺ�***********/
/********����moving average����ʷ����bar��r���µ�oos r sq*************/

/*����moving average����ʷ����bar��r���µ�oos r sq*/
data oos_rsq_7_d;
set subsample_1;
keep coid demeanret_weekly datelead y_fit demeanret_weekly_movingave;
run;

data oos_rsq_7_d;
set oos_rsq_7_d;
numerator=(demeanret_weekly-y_fit);
denominator=(demeanret_weekly-demeanret_weekly_movingave);
run;

proc sort data=oos_rsq_7_d;
by datelead coid;
run;

proc means data=oos_rsq_7_d noprint;
var numerator denominator;
output out=cal_12_d var(numerator denominator)=varnumerator vardenominator;
by datelead;
run;

data cal_12_d;
set cal_12_d;
oos_rsq_7_d=1-varnumerator/vardenominator;
run;

/*cal_13_d�еľ��ǲ�����ʷmoving average��Ϊ��ֵʱ�Ľ��*/
proc means data=cal_12_d noprint;
var oos_rsq_7_d;
output out=cal_13_d mean(oos_rsq_7_d)=oos_rsq_7_d;
run;

/******************************************************/
/*�����������ۼƾ�ֵ�µ�oos r sq*/
data oos_rsq_8_d;
set subsample_1;
keep coid demeanret_weekly datelead y_fit demeanret_weekly_accave;
run;

data oos_rsq_8_d;
set oos_rsq_8_d;
numerator=(demeanret_weekly-y_fit);
denominator=(demeanret_weekly-demeanret_weekly_accave);
run;

proc sort data=oos_rsq_8_d;
by datelead coid;
run;

proc means data=oos_rsq_8_d noprint;
var numerator denominator;
output out=cal_14_d var(numerator denominator)=varnumerator vardenominator;
by datelead;
run;

data cal_14_d;
set cal_14_d;
oos_rsq_8_d=1-varnumerator/vardenominator;
run;

/*cal_15_d�еľ��ǲ�����ʷaccumulated average��Ϊ��ֵʱ�Ľ��*/
proc means data=cal_14_d noprint;
var oos_rsq_8_d;
output out=cal_15_d mean(oos_rsq_8_d)=oos_rsq_8_d;
run;





/*********************************/
/*****�������Ǽ���pooling�Ľ��****/






/*�Ȱ��յ�һ�ַ�����һ��*/
/*����moving average����ʷ����bar��r���µ�oos r sq*/
data oos_rsq_5_p;
set subsample_1;
keep coid demeanret_weekly_movingave demeanret_weekly_moving_crosec 
demeanret_weekly demeanret_weekly_crosec datelead y_fit y_fit_crosec;
run;

data oos_rsq_5_p;
set oos_rsq_5_p;
numerator=(demeanret_weekly-demeanret_weekly_crosec-y_fit+y_fit_crosec)**2;
denominator=(demeanret_weekly-demeanret_weekly_crosec-demeanret_weekly_movingave+
demeanret_weekly_moving_crosec)**2;
run;

proc means data=oos_rsq_5_p noprint;
var numerator denominator;
output out=cal_8_p sum(numerator denominator)=sumnumerator sumdenominator;
run;

data cal_8_p;
set cal_8_p;
oos_rsq_5_p=1-sumnumerator/sumdenominator;
run;

/******************************************************/
/*�����������ۼƾ�ֵ�µ�oos r sq*/
data oos_rsq_6_p;
set subsample_1;
keep coid demeanret_weekly_accave demeanret_weekly_accave_crosec 
demeanret_weekly demeanret_weekly_crosec datelead y_fit y_fit_crosec;
run;

data oos_rsq_6_p;
set oos_rsq_6_p;
numerator=(demeanret_weekly-demeanret_weekly_crosec-y_fit+y_fit_crosec)**2;
denominator=(demeanret_weekly-demeanret_weekly_crosec-demeanret_weekly_accave
+demeanret_weekly_accave_crosec)**2;
run;

proc means data=oos_rsq_6_p noprint;
var numerator denominator;
output out=cal_10_p sum(numerator denominator)=sumnumerator sumdenominator;
run;

data cal_10_p;
set cal_10_p;
oos_rsq_6_p=1-sumnumerator/sumdenominator;
run;

/*******************************************************************/
/*�ٰ��յڶ��ַ�����һ�£�����ֱ����demean���е�variance�ͺ�***********/
/********����moving average����ʷ����bar��r���µ�oos r sq*************/

/*����moving average����ʷ����bar��r���µ�oos r sq*/
data oos_rsq_7_p;
set subsample_1;
keep coid demeanret_weekly datelead y_fit demeanret_weekly_movingave;
run;

data oos_rsq_7_p;
set oos_rsq_7_p;
numerator=(demeanret_weekly-y_fit);
denominator=(demeanret_weekly-demeanret_weekly_movingave);
run;

proc means data=oos_rsq_7_p noprint;
var numerator denominator;
output out=cal_12_p var(numerator denominator)=varnumerator vardenominator;
run;

data cal_12_p;
set cal_12_p;
oos_rsq_7_p=1-varnumerator/vardenominator;
run;

/******************************************************/
/*�����������ۼƾ�ֵ�µ�oos r sq*/
data oos_rsq_8_p;
set subsample_1;
keep coid demeanret_weekly datelead y_fit demeanret_weekly_accave;
run;

data oos_rsq_8_p;
set oos_rsq_8_p;
numerator=(demeanret_weekly-y_fit);
denominator=(demeanret_weekly-demeanret_weekly_accave);
run;

proc means data=oos_rsq_8_p noprint;
var numerator denominator;
output out=cal_14_p var(numerator denominator)=varnumerator vardenominator;
run;

data cal_14_p;
set cal_14_p;
oos_rsq_8_p=1-varnumerator/vardenominator;
run;







/******************************************************************/
/**************�������֣�����subsample2��oos r sq*******************/
/******************************************************************/

data subsample_2;
set rank_1;
if (rank_y_fit<(maxrank*0.8))&& (rank_y_fit>=(maxrank*0.2));
drop _TYPE_ _FREQ_;
run;

proc sort data=subsample_2;
by coid;
run;

/*�Ȱ��յ�һ�ַ�����һ��*/
/*����moving average����ʷ����bar��r���µ�oos r sq*/
data oos_rsq_9;
set subsample_2;
keep coid demeanret_weekly_movingave demeanret_weekly_moving_crosec 
demeanret_weekly demeanret_weekly_crosec datelead y_fit y_fit_crosec;
run;

data oos_rsq_9;
set oos_rsq_9;
numerator=(demeanret_weekly-demeanret_weekly_crosec-y_fit+y_fit_crosec)**2;
denominator=(demeanret_weekly-demeanret_weekly_crosec-demeanret_weekly_movingave+
demeanret_weekly_moving_crosec)**2;
run;

proc means data=oos_rsq_9 noprint;
var numerator denominator;
output out=cal_16 sum(numerator denominator)=sumnumerator sumdenominator;
by coid;
run;

data cal_16;
set cal_16;
oos_rsq_9=1-sumnumerator/sumdenominator;
run;

/*cal_17�еľ��ǲ�����ʷmoving average��Ϊ��ֵʱ�Ľ��*/
proc means data=cal_16 noprint;
var oos_rsq_9;
output out=cal_17 mean(oos_rsq_9)=oos_rsq_9;
run;
/******************************************************/
/*�����������ۼƾ�ֵ�µ�oos r sq*/
data oos_rsq_10;
set subsample_2;
keep coid demeanret_weekly_accave demeanret_weekly_accave_crosec 
demeanret_weekly demeanret_weekly_crosec datelead y_fit y_fit_crosec;
run;

data oos_rsq_10;
set oos_rsq_10;
numerator=(demeanret_weekly-demeanret_weekly_crosec-y_fit+y_fit_crosec)**2;
denominator=(demeanret_weekly-demeanret_weekly_crosec-demeanret_weekly_accave
+demeanret_weekly_accave_crosec)**2;
run;

proc means data=oos_rsq_10 noprint;
var numerator denominator;
output out=cal_18 sum(numerator denominator)=sumnumerator sumdenominator;
by coid;
run;

data cal_18;
set cal_18;
oos_rsq_10=1-sumnumerator/sumdenominator;
run;

/*cal_19�еľ��ǲ�����ʷaccumulated average��Ϊ��ֵʱ�Ľ��*/
proc means data=cal_18 noprint;
var oos_rsq_10;
output out=cal_19 mean(oos_rsq_10)=oos_rsq_10;
run;

/*******************************************************************/
/*�ٰ��յڶ��ַ�����һ�£�����ֱ����demean���е�variance�ͺ�***********/
/********����moving average����ʷ����bar��r���µ�oos r sq*************/

/*����moving average����ʷ����bar��r���µ�oos r sq*/
data oos_rsq_11;
set subsample_2;
keep coid demeanret_weekly datelead y_fit demeanret_weekly_movingave;
run;

data oos_rsq_11;
set oos_rsq_11;
numerator=(demeanret_weekly-y_fit);
denominator=(demeanret_weekly-demeanret_weekly_movingave);
run;

proc means data=oos_rsq_11 noprint;
var numerator denominator;
output out=cal_20 var(numerator denominator)=varnumerator vardenominator;
by coid;
run;

data cal_20;
set cal_20;
oos_rsq_11=1-varnumerator/vardenominator;
run;

/*cal_21�еľ��ǲ�����ʷmoving average��Ϊ��ֵʱ�Ľ��*/
proc means data=cal_20 noprint;
var oos_rsq_11;
output out=cal_21 mean(oos_rsq_11)=oos_rsq_11;
run;

/******************************************************/
/*�����������ۼƾ�ֵ�µ�oos r sq*/
data oos_rsq_12;
set subsample_2;
keep coid demeanret_weekly datelead y_fit demeanret_weekly_accave;
run;

data oos_rsq_12;
set oos_rsq_12;
numerator=(demeanret_weekly-y_fit);
denominator=(demeanret_weekly-demeanret_weekly_accave);
run;

proc means data=oos_rsq_12 noprint;
var numerator denominator;
output out=cal_22 var(numerator denominator)=varnumerator vardenominator;
by coid;
run;

data cal_22;
set cal_22;
oos_rsq_12=1-varnumerator/vardenominator;
run;

/*cal_23�еľ��ǲ�����ʷaccumulated average��Ϊ��ֵʱ�Ľ��*/
proc means data=cal_22 noprint;
var oos_rsq_12;
output out=cal_23 mean(oos_rsq_12)=oos_rsq_12;
run;





/***********************/
/*����������by date�Ľ��*/





/*�Ȱ��յ�һ�ַ�����һ��*/
/*����moving average����ʷ����bar��r���µ�oos r sq*/
data oos_rsq_9_d;
set subsample_2;
keep coid demeanret_weekly_movingave demeanret_weekly_moving_crosec 
demeanret_weekly demeanret_weekly_crosec datelead y_fit y_fit_crosec;
run;

data oos_rsq_9_d;
set oos_rsq_9_d;
numerator=(demeanret_weekly-demeanret_weekly_crosec-y_fit+y_fit_crosec)**2;
denominator=(demeanret_weekly-demeanret_weekly_crosec-demeanret_weekly_movingave+
demeanret_weekly_moving_crosec)**2;
run;

proc sort data=oos_rsq_9_d;
by datelead coid;
run;

proc means data=oos_rsq_9_d noprint;
var numerator denominator;
output out=cal_16_d sum(numerator denominator)=sumnumerator sumdenominator;
by datelead;
run;

data cal_16_d;
set cal_16_d;
oos_rsq_9_d=1-sumnumerator/sumdenominator;
run;

/*cal_17_d�еľ��ǲ�����ʷmoving average��Ϊ��ֵʱ�Ľ��*/
proc means data=cal_16_d noprint;
var oos_rsq_9_d;
output out=cal_17_d mean(oos_rsq_9_d)=oos_rsq_9_d;
run;
/******************************************************/
/*�����������ۼƾ�ֵ�µ�oos r sq*/
data oos_rsq_10_d;
set subsample_2;
keep coid demeanret_weekly_accave demeanret_weekly_accave_crosec 
demeanret_weekly demeanret_weekly_crosec datelead y_fit y_fit_crosec;
run;

data oos_rsq_10_d;
set oos_rsq_10_d;
numerator=(demeanret_weekly-demeanret_weekly_crosec-y_fit+y_fit_crosec)**2;
denominator=(demeanret_weekly-demeanret_weekly_crosec-demeanret_weekly_accave
+demeanret_weekly_accave_crosec)**2;
run;

proc sort data=oos_rsq_10_d;
by datelead coid;
run;

proc means data=oos_rsq_10_d noprint;
var numerator denominator;
output out=cal_18_d sum(numerator denominator)=sumnumerator sumdenominator;
by datelead;
run;

data cal_18_d;
set cal_18_d;
oos_rsq_10_d=1-sumnumerator/sumdenominator;
run;

/*cal_19_d�еľ��ǲ�����ʷaccumulated average��Ϊ��ֵʱ�Ľ��*/
proc means data=cal_18_d noprint;
var oos_rsq_10_d;
output out=cal_19_d mean(oos_rsq_10_d)=oos_rsq_10_d;
run;

/*******************************************************************/
/*�ٰ��յڶ��ַ�����һ�£�����ֱ����demean���е�variance�ͺ�***********/
/********����moving average����ʷ����bar��r���µ�oos r sq*************/

/*����moving average����ʷ����bar��r���µ�oos r sq*/
data oos_rsq_11_d;
set subsample_2;
keep coid demeanret_weekly datelead y_fit demeanret_weekly_movingave;
run;

data oos_rsq_11_d;
set oos_rsq_11_d;
numerator=(demeanret_weekly-y_fit);
denominator=(demeanret_weekly-demeanret_weekly_movingave);
run;

proc sort data=oos_rsq_11_d;
by datelead coid;
run;

proc means data=oos_rsq_11_d noprint;
var numerator denominator;
output out=cal_20_d var(numerator denominator)=varnumerator vardenominator;
by datelead;
run;

data cal_20_d;
set cal_20_d;
oos_rsq_11_d=1-varnumerator/vardenominator;
run;

/*cal_21_d�еľ��ǲ�����ʷmoving average��Ϊ��ֵʱ�Ľ��*/
proc means data=cal_20_d noprint;
var oos_rsq_11_d;
output out=cal_21_d mean(oos_rsq_11_d)=oos_rsq_11_d;
run;

/******************************************************/
/*�����������ۼƾ�ֵ�µ�oos r sq*/
data oos_rsq_12_d;
set subsample_2;
keep coid demeanret_weekly datelead y_fit demeanret_weekly_accave;
run;

data oos_rsq_12_d;
set oos_rsq_12_d;
numerator=(demeanret_weekly-y_fit);
denominator=(demeanret_weekly-demeanret_weekly_accave);
run;

proc sort data=oos_rsq_12_d;
by datelead coid;
run;

proc means data=oos_rsq_12_d noprint;
var numerator denominator;
output out=cal_22_d var(numerator denominator)=varnumerator vardenominator;
by datelead;
run;

data cal_22_d;
set cal_22_d;
oos_rsq_12_d=1-varnumerator/vardenominator;
run;

/*cal_23_d�еľ��ǲ�����ʷaccumulated average��Ϊ��ֵʱ�Ľ��*/
proc means data=cal_22_d noprint;
var oos_rsq_12_d;
output out=cal_23_d mean(oos_rsq_12_d)=oos_rsq_12_d;
run;




/*3���pooling�Ľ��*/






/*�Ȱ��յ�һ�ַ�����һ��*/
/*����moving average����ʷ����bar��r���µ�oos r sq*/
data oos_rsq_9_p;
set subsample_2;
keep coid demeanret_weekly_movingave demeanret_weekly_moving_crosec 
demeanret_weekly demeanret_weekly_crosec datelead y_fit y_fit_crosec;
run;

data oos_rsq_9_p;
set oos_rsq_9_p;
numerator=(demeanret_weekly-demeanret_weekly_crosec-y_fit+y_fit_crosec)**2;
denominator=(demeanret_weekly-demeanret_weekly_crosec-demeanret_weekly_movingave+
demeanret_weekly_moving_crosec)**2;
run;

proc means data=oos_rsq_9_p noprint;
var numerator denominator;
output out=cal_16_p sum(numerator denominator)=sumnumerator sumdenominator;
run;

data cal_16_p;
set cal_16_p;
oos_rsq_9_p=1-sumnumerator/sumdenominator;
run;

/******************************************************/
/*�����������ۼƾ�ֵ�µ�oos r sq*/
data oos_rsq_10_p;
set subsample_2;
keep coid demeanret_weekly_accave demeanret_weekly_accave_crosec 
demeanret_weekly demeanret_weekly_crosec datelead y_fit y_fit_crosec;
run;

data oos_rsq_10_p;
set oos_rsq_10_p;
numerator=(demeanret_weekly-demeanret_weekly_crosec-y_fit+y_fit_crosec)**2;
denominator=(demeanret_weekly-demeanret_weekly_crosec-demeanret_weekly_accave
+demeanret_weekly_accave_crosec)**2;
run;

proc means data=oos_rsq_10_p noprint;
var numerator denominator;
output out=cal_18_p sum(numerator denominator)=sumnumerator sumdenominator;
run;

data cal_18_p;
set cal_18_p;
oos_rsq_10_p=1-sumnumerator/sumdenominator;
run;

/*******************************************************************/
/*�ٰ��յڶ��ַ�����һ�£�����ֱ����demean���е�variance�ͺ�***********/
/********����moving average����ʷ����bar��r���µ�oos r sq*************/

/*����moving average����ʷ����bar��r���µ�oos r sq*/
data oos_rsq_11_p;
set subsample_2;
keep coid demeanret_weekly datelead y_fit demeanret_weekly_movingave;
run;

data oos_rsq_11_p;
set oos_rsq_11_p;
numerator=(demeanret_weekly-y_fit);
denominator=(demeanret_weekly-demeanret_weekly_movingave);
run;

proc means data=oos_rsq_11_p noprint;
var numerator denominator;
output out=cal_20_p var(numerator denominator)=varnumerator vardenominator;
run;

data cal_20_p;
set cal_20_p;
oos_rsq_11_p=1-varnumerator/vardenominator;
run;

/******************************************************/
/*�����������ۼƾ�ֵ�µ�oos r sq*/
data oos_rsq_12_p;
set subsample_2;
keep coid demeanret_weekly datelead y_fit demeanret_weekly_accave;
run;

data oos_rsq_12_p;
set oos_rsq_12_p;
numerator=(demeanret_weekly-y_fit);
denominator=(demeanret_weekly-demeanret_weekly_accave);
run;

proc means data=oos_rsq_12_p noprint;
var numerator denominator;
output out=cal_22_p var(numerator denominator)=varnumerator vardenominator;
run;

data cal_22_p;
set cal_22_p;
oos_rsq_12_p=1-varnumerator/vardenominator;
run;





/******************************************************************/
/**************���߲��֣�����subsample3��oos r sq*******************/
/******************************************************************/
data subsample_3;
set rank_1;
if rank_y_fit<(maxrank*0.2);
drop _TYPE_ _FREQ_;
run;

proc sort data=subsample_3;
by coid;
run;

/*�Ȱ��յ�һ�ַ�����һ��*/
/*����moving average����ʷ����bar��r���µ�oos r sq*/
data oos_rsq_13;
set subsample_3;
keep coid demeanret_weekly_movingave demeanret_weekly_moving_crosec 
demeanret_weekly demeanret_weekly_crosec datelead y_fit y_fit_crosec;
run;

data oos_rsq_13;
set oos_rsq_13;
numerator=(demeanret_weekly-demeanret_weekly_crosec-y_fit+y_fit_crosec)**2;
denominator=(demeanret_weekly-demeanret_weekly_crosec-demeanret_weekly_movingave+
demeanret_weekly_moving_crosec)**2;
run;

proc means data=oos_rsq_13 noprint;
var numerator denominator;
output out=cal_24 sum(numerator denominator)=sumnumerator sumdenominator;
by coid;
run;

data cal_24;
set cal_24;
oos_rsq_13=1-sumnumerator/sumdenominator;
run;

/*cal_25�еľ��ǲ�����ʷmoving average��Ϊ��ֵʱ�Ľ��*/
proc means data=cal_24 noprint;
var oos_rsq_13;
output out=cal_25 mean(oos_rsq_13)=oos_rsq_13;
run;
/******************************************************/
/*�����������ۼƾ�ֵ�µ�oos r sq*/
data oos_rsq_14;
set subsample_3;
keep coid demeanret_weekly_accave demeanret_weekly_accave_crosec 
demeanret_weekly demeanret_weekly_crosec datelead y_fit y_fit_crosec;
run;

data oos_rsq_14;
set oos_rsq_14;
numerator=(demeanret_weekly-demeanret_weekly_crosec-y_fit+y_fit_crosec)**2;
denominator=(demeanret_weekly-demeanret_weekly_crosec-demeanret_weekly_accave
+demeanret_weekly_accave_crosec)**2;
run;

proc means data=oos_rsq_14 noprint;
var numerator denominator;
output out=cal_26 sum(numerator denominator)=sumnumerator sumdenominator;
by coid;
run;

data cal_26;
set cal_26;
oos_rsq_14=1-sumnumerator/sumdenominator;
run;

/*cal_27�еľ��ǲ�����ʷaccumulated average��Ϊ��ֵʱ�Ľ��*/
proc means data=cal_26 noprint;
var oos_rsq_14;
output out=cal_27 mean(oos_rsq_14)=oos_rsq_14;
run;

/*******************************************************************/
/*�ٰ��յڶ��ַ�����һ�£�����ֱ����demean���е�variance�ͺ�***********/
/********����moving average����ʷ����bar��r���µ�oos r sq*************/

/*����moving average����ʷ����bar��r���µ�oos r sq*/
data oos_rsq_15;
set subsample_3;
keep coid demeanret_weekly datelead y_fit demeanret_weekly_movingave;
run;

data oos_rsq_15;
set oos_rsq_15;
numerator=(demeanret_weekly-y_fit);
denominator=(demeanret_weekly-demeanret_weekly_movingave);
run;

proc means data=oos_rsq_15 noprint;
var numerator denominator;
output out=cal_28 var(numerator denominator)=varnumerator vardenominator;
by coid;
run;

data cal_28;
set cal_28;
oos_rsq_15=1-varnumerator/vardenominator;
run;

/*cal_29�еľ��ǲ�����ʷmoving average��Ϊ��ֵʱ�Ľ��*/
proc means data=cal_28 noprint;
var oos_rsq_15;
output out=cal_29 mean(oos_rsq_15)=oos_rsq_15;
run;

/******************************************************/
/*�����������ۼƾ�ֵ�µ�oos r sq*/
data oos_rsq_16;
set subsample_3;
keep coid demeanret_weekly datelead y_fit demeanret_weekly_accave;
run;

data oos_rsq_16;
set oos_rsq_16;
numerator=(demeanret_weekly-y_fit);
denominator=(demeanret_weekly-demeanret_weekly_accave);
run;

proc means data=oos_rsq_16 noprint;
var numerator denominator;
output out=cal_30 var(numerator denominator)=varnumerator vardenominator;
by coid;
run;

data cal_30;
set cal_30;
oos_rsq_16=1-varnumerator/vardenominator;
run;

/*cal_31�еľ��ǲ�����ʷaccumulated average��Ϊ��ֵʱ�Ľ��*/
proc means data=cal_30 noprint;
var oos_rsq_16;
output out=cal_31 mean(oos_rsq_16)=oos_rsq_16;
run;





/*�������dateȡ��ֵ�Ľ��*/






/*�Ȱ��յ�һ�ַ�����һ��*/
/*����moving average����ʷ����bar��r���µ�oos r sq*/
data oos_rsq_13_d;
set subsample_3;
keep coid demeanret_weekly_movingave demeanret_weekly_moving_crosec 
demeanret_weekly demeanret_weekly_crosec datelead y_fit y_fit_crosec;
run;

data oos_rsq_13_d;
set oos_rsq_13_d;
numerator=(demeanret_weekly-demeanret_weekly_crosec-y_fit+y_fit_crosec)**2;
denominator=(demeanret_weekly-demeanret_weekly_crosec-demeanret_weekly_movingave+
demeanret_weekly_moving_crosec)**2;
run;

proc sort data=oos_rsq_13_d;
by datelead coid;
run;

proc means data=oos_rsq_13_d noprint;
var numerator denominator;
output out=cal_24_d sum(numerator denominator)=sumnumerator sumdenominator;
by datelead;
run;

data cal_24_d;
set cal_24_d;
oos_rsq_13_d=1-sumnumerator/sumdenominator;
run;

/*cal_25_d�еľ��ǲ�����ʷmoving average��Ϊ��ֵʱ�Ľ��*/
proc means data=cal_24_d noprint;
var oos_rsq_13_d;
output out=cal_25_d mean(oos_rsq_13_d)=oos_rsq_13_d;
run;

/******************************************************/
/*�����������ۼƾ�ֵ�µ�oos r sq*/
data oos_rsq_14_d;
set subsample_3;
keep coid demeanret_weekly_accave demeanret_weekly_accave_crosec 
demeanret_weekly demeanret_weekly_crosec datelead y_fit y_fit_crosec;
run;

data oos_rsq_14_d;
set oos_rsq_14_d;
numerator=(demeanret_weekly-demeanret_weekly_crosec-y_fit+y_fit_crosec)**2;
denominator=(demeanret_weekly-demeanret_weekly_crosec-demeanret_weekly_accave
+demeanret_weekly_accave_crosec)**2;
run;

proc sort data=oos_rsq_14_d;
by datelead coid;
run;

proc means data=oos_rsq_14_d noprint;
var numerator denominator;
output out=cal_26_d sum(numerator denominator)=sumnumerator sumdenominator;
by datelead;
run;

data cal_26_d;
set cal_26_d;
oos_rsq_14_d=1-sumnumerator/sumdenominator;
run;

/*cal_27_d�еľ��ǲ�����ʷaccumulated average��Ϊ��ֵʱ�Ľ��*/
proc means data=cal_26_d noprint;
var oos_rsq_14_d;
output out=cal_27_d mean(oos_rsq_14_d)=oos_rsq_14_d;
run;

/*******************************************************************/
/*�ٰ��յڶ��ַ�����һ�£�����ֱ����demean���е�variance�ͺ�***********/
/********����moving average����ʷ����bar��r���µ�oos r sq*************/

/*����moving average����ʷ����bar��r���µ�oos r sq*/
data oos_rsq_15_d;
set subsample_3;
keep coid demeanret_weekly datelead y_fit demeanret_weekly_movingave;
run;

data oos_rsq_15_d;
set oos_rsq_15_d;
numerator=(demeanret_weekly-y_fit);
denominator=(demeanret_weekly-demeanret_weekly_movingave);
run;

proc sort data=oos_rsq_15_d;
by datelead coid;
run;

proc means data=oos_rsq_15_d noprint;
var numerator denominator;
output out=cal_28_d var(numerator denominator)=varnumerator vardenominator;
by datelead;
run;

data cal_28_d;
set cal_28_d;
oos_rsq_15_d=1-varnumerator/vardenominator;
run;

/*cal_29_d�еľ��ǲ�����ʷmoving average��Ϊ��ֵʱ�Ľ��*/
proc means data=cal_28_d noprint;
var oos_rsq_15_d;
output out=cal_29_d mean(oos_rsq_15_d)=oos_rsq_15_d;
run;

/******************************************************/
/*�����������ۼƾ�ֵ�µ�oos r sq*/
data oos_rsq_16_d;
set subsample_3;
keep coid demeanret_weekly datelead y_fit demeanret_weekly_accave;
run;

proc sort data=oos_rsq_16_d;
by datelead coid;
run;

data oos_rsq_16_d;
set oos_rsq_16_d;
numerator=(demeanret_weekly-y_fit);
denominator=(demeanret_weekly-demeanret_weekly_accave);
run;

proc means data=oos_rsq_16_d noprint;
var numerator denominator;
output out=cal_30_d var(numerator denominator)=varnumerator vardenominator;
by datelead;
run;

data cal_30_d;
set cal_30_d;
oos_rsq_16_d=1-varnumerator/vardenominator;
run;

/*cal_31_d�еľ��ǲ�����ʷaccumulated average��Ϊ��ֵʱ�Ľ��*/
proc means data=cal_30_d noprint;
var oos_rsq_16_d;
output out=cal_31_d mean(oos_rsq_16_d)=oos_rsq_16_d;
run;



/*��������һ��pooling�Ľ��*/






/*�Ȱ��յ�һ�ַ�����һ��*/
/*����moving average����ʷ����bar��r���µ�oos r sq*/
data oos_rsq_13_p;
set subsample_3;
keep coid demeanret_weekly_movingave demeanret_weekly_moving_crosec 
demeanret_weekly demeanret_weekly_crosec datelead y_fit y_fit_crosec;
run;

data oos_rsq_13_p;
set oos_rsq_13_p;
numerator=(demeanret_weekly-demeanret_weekly_crosec-y_fit+y_fit_crosec)**2;
denominator=(demeanret_weekly-demeanret_weekly_crosec-demeanret_weekly_movingave+
demeanret_weekly_moving_crosec)**2;
run;

proc means data=oos_rsq_13_p noprint;
var numerator denominator;
output out=cal_24_p sum(numerator denominator)=sumnumerator sumdenominator;
run;

data cal_24_p;
set cal_24_p;
oos_rsq_13_p=1-sumnumerator/sumdenominator;
run;

/******************************************************/
/*�����������ۼƾ�ֵ�µ�oos r sq*/
data oos_rsq_14_p;
set subsample_3;
keep coid demeanret_weekly_accave demeanret_weekly_accave_crosec 
demeanret_weekly demeanret_weekly_crosec datelead y_fit y_fit_crosec;
run;

data oos_rsq_14_p;
set oos_rsq_14_p;
numerator=(demeanret_weekly-demeanret_weekly_crosec-y_fit+y_fit_crosec)**2;
denominator=(demeanret_weekly-demeanret_weekly_crosec-demeanret_weekly_accave
+demeanret_weekly_accave_crosec)**2;
run;

proc means data=oos_rsq_14_p noprint;
var numerator denominator;
output out=cal_26_p sum(numerator denominator)=sumnumerator sumdenominator;
run;

data cal_26_p;
set cal_26_p;
oos_rsq_14_p=1-sumnumerator/sumdenominator;
run;

/*******************************************************************/
/*�ٰ��յڶ��ַ�����һ�£�����ֱ����demean���е�variance�ͺ�***********/
/********����moving average����ʷ����bar��r���µ�oos r sq*************/

/*����moving average����ʷ����bar��r���µ�oos r sq*/
data oos_rsq_15_p;
set subsample_3;
keep coid demeanret_weekly datelead y_fit demeanret_weekly_movingave;
run;

data oos_rsq_15_p;
set oos_rsq_15_p;
numerator=(demeanret_weekly-y_fit);
denominator=(demeanret_weekly-demeanret_weekly_movingave);
run;

proc means data=oos_rsq_15_p noprint;
var numerator denominator;
output out=cal_28_p var(numerator denominator)=varnumerator vardenominator;
run;

data cal_28_p;
set cal_28_p;
oos_rsq_15_p=1-varnumerator/vardenominator;
run;

/******************************************************/
/*�����������ۼƾ�ֵ�µ�oos r sq*/
data oos_rsq_16_p;
set subsample_3;
keep coid demeanret_weekly datelead y_fit demeanret_weekly_accave;
run;

data oos_rsq_16_p;
set oos_rsq_16_p;
numerator=(demeanret_weekly-y_fit);
denominator=(demeanret_weekly-demeanret_weekly_accave);
run;

proc means data=oos_rsq_16_p noprint;
var numerator denominator;
output out=cal_30_p var(numerator denominator)=varnumerator vardenominator;
run;

data cal_30_p;
set cal_30_p;
oos_rsq_16_p=1-varnumerator/vardenominator;
run;





/******************************************************************/
/**************�ڰ˲��֣�����rank��correlation**********************/
/******************************************************************/


/*����������ʵret��Y-fit��moving average��accumulated average������rank*/

proc rank data=r_rho out=rank_2;
var demeanret_weekly;
ranks demeanrank_ret_weekly;
by datelead;
run;

proc rank data=rank_2 out=rank_3;
var y_fit;
ranks rank_y_fit;
by datelead;
run;

proc rank data=rank_3 out=rank_4;
var demeanret_weekly_movingave;
ranks demeanrank_ret_weekly_movingave;
by datelead;
run;

proc rank data=rank_4 out=rank_5;
var demeanret_weekly_accave;
ranks demeanrank_ret_weekly_accave;
by datelead;
run;

proc datasets library=work nolist;
modify rank_5;
attrib _all_ label="";
quit;

/*����correlation*/
 PROC CORR SPEARMAN data=rank_5 outp=corr noprint; 
var rank_y_fit demeanrank_ret_weekly_movingave demeanrank_ret_weekly_accave ;
with demeanret_weekly;
by datelead;
RUN; 

data corr;
set corr;
if _TYPE_='CORR' && rank_y_fit~=.;
run;

proc means data=corr noprint;
var rank_y_fit demeanrank_ret_weekly_movingave demeanrank_ret_weekly_accave;
output out=corr_result mean(rank_y_fit demeanrank_ret_weekly_movingave 
demeanrank_ret_weekly_accave)=corr_y_fit corr_weekly_movingave corr_ret_weekly_accave;
run;

/*��subsample��rank correlationЧ��*/

/*subsample1*/

proc sort data=subsample_1;
by datelead;
run;

proc rank data=subsample_1 out=rank_6;
var demeanret_weekly;
ranks demeanrank_ret_weekly;
by datelead;
run;

proc rank data=rank_6 out=rank_7;
var y_fit;
ranks rank_y_fit;
by datelead;
run;

proc rank data=rank_7 out=rank_8;
var demeanret_weekly_movingave;
ranks demeanrank_ret_weekly_movingave;
by datelead;
run;

proc rank data=rank_8 out=rank_9;
var demeanret_weekly_accave;
ranks demeanrank_ret_weekly_accave;
by datelead;
run;

proc datasets library=work nolist;
modify rank_9;
attrib _all_ label="";
quit;

/*����correlation*/
 PROC CORR SPEARMAN data=rank_9 outp=corr_1 noprint; 
var rank_y_fit demeanrank_ret_weekly_movingave demeanrank_ret_weekly_accave ;
with demeanret_weekly;
by datelead;
RUN; 

data corr_1;
set corr_1;
if _TYPE_='CORR' && rank_y_fit~=.;
run;

proc means data=corr_1 noprint;
var rank_y_fit demeanrank_ret_weekly_movingave demeanrank_ret_weekly_accave;
output out=corr_result_1 mean(rank_y_fit demeanrank_ret_weekly_movingave 
demeanrank_ret_weekly_accave)=corr_y_fit corr_weekly_movingave corr_ret_weekly_accave;
run;

/*subsample2*/

proc sort data=subsample_2;
by datelead;
run;

proc rank data=subsample_2 out=rank_10;
var demeanret_weekly;
ranks demeanrank_ret_weekly;
by datelead;
run;

proc rank data=rank_10 out=rank_11;
var y_fit;
ranks rank_y_fit;
by datelead;
run;

proc rank data=rank_11 out=rank_12;
var demeanret_weekly_movingave;
ranks demeanrank_ret_weekly_movingave;
by datelead;
run;

proc rank data=rank_12 out=rank_13;
var demeanret_weekly_accave;
ranks demeanrank_ret_weekly_accave;
by datelead;
run;

proc datasets library=work nolist;
modify rank_13;
attrib _all_ label="";
quit;

/*����correlation*/
 PROC CORR SPEARMAN data=rank_13 outp=corr_2 noprint; 
var rank_y_fit demeanrank_ret_weekly_movingave demeanrank_ret_weekly_accave ;
with demeanret_weekly;
by datelead;
RUN; 

data corr_2;
set corr_2;
if _TYPE_='CORR' && rank_y_fit~=.;
run;

proc means data=corr_2 noprint;
var rank_y_fit demeanrank_ret_weekly_movingave demeanrank_ret_weekly_accave;
output out=corr_result_2 mean(rank_y_fit demeanrank_ret_weekly_movingave 
demeanrank_ret_weekly_accave)=corr_y_fit corr_weekly_movingave corr_ret_weekly_accave;
run;


/*subsample3*/

proc sort data=subsample_3;
by datelead;
run;

proc rank data=subsample_3 out=rank_17;
var demeanret_weekly;
ranks demeanrank_ret_weekly;
by datelead;
run;

proc rank data=rank_17 out=rank_18;
var y_fit;
ranks rank_y_fit;
by datelead;
run;

proc rank data=rank_18 out=rank_19;
var demeanret_weekly_movingave;
ranks demeanrank_ret_weekly_movingave;
by datelead;
run;

proc rank data=rank_19 out=rank_20;
var demeanret_weekly_accave;
ranks demeanrank_ret_weekly_accave;
by datelead;
run;

proc datasets library=work nolist;
modify rank_20;
attrib _all_ label="";
quit;

/*����correlation*/
 PROC CORR SPEARMAN data=rank_20 outp=corr_3 noprint; 
var rank_y_fit demeanrank_ret_weekly_movingave demeanrank_ret_weekly_accave ;
with demeanret_weekly;
by datelead;
RUN; 

data corr_3;
set corr_3;
if _TYPE_='CORR' && rank_y_fit~=.;
run;

proc means data=corr_3 noprint;
var rank_y_fit demeanrank_ret_weekly_movingave demeanrank_ret_weekly_accave;
output out=corr_result_3 mean(rank_y_fit demeanrank_ret_weekly_movingave 
demeanrank_ret_weekly_accave)=corr_y_fit corr_weekly_movingave corr_ret_weekly_accave;
run;














/******************************************************************/
/**************�ھŲ��֣�����rho����Ӧ��in-sample r sq**************/
/******************************************************************/
