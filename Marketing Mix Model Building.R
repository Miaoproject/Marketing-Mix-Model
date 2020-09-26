
library(readxl)

AF= read_excel("AF.xlsx")

AF$Period=as.Date(AF$Period,"%d/%m/%Y")

AF[,"Black_Friday"]=0

AF[which(AF$Period=='2014-11-24'),"Black_Friday"]=1
AF[which(AF$Period=='2015-11-30'),"Black_Friday"]=1
AF[which(AF$Period=='2016-11-28'),"Black_Friday"]=1
AF[which(AF$Period=='2017-11-27'),"Black_Friday"]=1

AF[,"July_4th"]=0
AF[which(AF$Period=='2014-7-7'),"July_4th"]=1
AF[which(AF$Period=='2015-7-6'),"July_4th"]=1
AF[which(AF$Period=='2016-7-4'),"July_4th"]=1
AF[which(AF$Period=='2017-7-3'),"July_4th"]=1

colnames(AF)[2]="National_TV"
colnames(AF)[4]="Paid_Search"
colnames(AF)[9]="Sales_Event"
colnames(AF)[10]="Comp_Media_Spend"


model=lm(Sales~Black_Friday+July_4th+Sales_Event+CCI+National_TV+Paid_Search+Wechat+Display+Magazine+Facebook,data=AF,x=TRUE)
summary(model)

Contribution=sweep(model$x,MARGIN=2,model$coefficients,"*")
Contribution_frame=as.data.frame(Contribution)
Contribution_frame$Period=AF$Period

library(reshape)
Contri=melt(Contribution_frame,id.vars="Period",measure.vars = names(model$coefficients))
write.csv(Contri,"Contribution.csv",row.names = FALSE)

AVM=cbind(AF[,"Period"],AF[,"Sales"],model$fitted.values)
colnames(AVM)[3]="Modeled_sales"
write.csv(AVM,"AVM.csv",row.names = FALSE)

model$coefficients
