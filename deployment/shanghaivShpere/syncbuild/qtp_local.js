module.exports = {
    z7folders :[
                    {z7name:'DVD', folder:'/SetupBuilder/Output/UFT/DVD_Wix/*'},
    				{z7name:'Prerequisites', folder:'/SetupBuilder/Output/UFT/Prerequisites/*'},
					{z7name:'QTP_OUTPUT_DIR', folder:'/QTP/QTP_OUTPUT_DIR/*'}
                ],
    z7option : {
			v: '60m',
			m4: '=lzma2',
			mmt: '=16',
			x: '@ignore.txt'
		}
    
}