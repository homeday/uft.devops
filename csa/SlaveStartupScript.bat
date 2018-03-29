rem echo "Command executed">C:\Command.txt
echo off
for /f %%i in ('hostname') do set Host=%%i


SET UpperCaseHost=%Host%
IF [%UpperCaseHost%]==[] GOTO Ending
SET UpperCaseHost=%UpperCaseHost:a=A%
SET UpperCaseHost=%UpperCaseHost:b=B%
SET UpperCaseHost=%UpperCaseHost:c=C%
SET UpperCaseHost=%UpperCaseHost:d=D%
SET UpperCaseHost=%UpperCaseHost:e=E%
SET UpperCaseHost=%UpperCaseHost:f=F%
SET UpperCaseHost=%UpperCaseHost:g=G%
SET UpperCaseHost=%UpperCaseHost:h=H%
SET UpperCaseHost=%UpperCaseHost:i=I%
SET UpperCaseHost=%UpperCaseHost:j=J%
SET UpperCaseHost=%UpperCaseHost:k=K%
SET UpperCaseHost=%UpperCaseHost:l=L%
SET UpperCaseHost=%UpperCaseHost:m=M%
SET UpperCaseHost=%UpperCaseHost:n=N%
SET UpperCaseHost=%UpperCaseHost:o=O%
SET UpperCaseHost=%UpperCaseHost:p=P%
SET UpperCaseHost=%UpperCaseHost:q=Q%
SET UpperCaseHost=%UpperCaseHost:r=R%
SET UpperCaseHost=%UpperCaseHost:s=S%
SET UpperCaseHost=%UpperCaseHost:t=T%
SET UpperCaseHost=%UpperCaseHost:u=U%
SET UpperCaseHost=%UpperCaseHost:v=V%
SET UpperCaseHost=%UpperCaseHost:w=W%
SET UpperCaseHost=%UpperCaseHost:x=X%
SET UpperCaseHost=%UpperCaseHost:y=Y%
SET UpperCaseHost=%UpperCaseHost:z=Z%
:Ending


echo on

w32tm /resync
java -jar slave.jar -jnlpUrl http://mydtbld0136.hpeswlab.net:8080/computer/SRF_QA_%UpperCaseHost%/slave-agent.jnlp 