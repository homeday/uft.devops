# This is for multiple qtp repositories operation like :
* Remove tag
	```
	bash ./qtprepos_operation.sh [Label] remove tags [tag name]
	```
* Update tag base on other tag - the tagert tag will be created if it doesn't exist
	```
	bash ./qtprepos_operation.sh [Label] update tags [tag name] tags [source tag name] 
	```
	
#### 1. Create a new reference - [branch or tag]
	```
	bash ./qtprepos_operation.sh [Label] update [reference type] [reference name] [reference type] [source reference name] 
	```
	Label : QTP Label like UFT_14_50
	The reference type can be a tags or heads - heads is for branch situation
	
	
#### 2. delete a new reference - [branch or tag]
	```
	bash ./qtprepos_operation.sh [Label] delete [reference type] [reference name] 
	```
	Label : QTP Label like UFT_14_50
	The reference type can be a tags or heads - heads is for branch situation	