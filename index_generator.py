import sys,os
f1=open('./index.html', 'w+')
print >>f1,""

for path, subdirs, files in os.walk("."):
        for name in files:
	        file = os.path.join(path, name)
		if file.startswith('./.git') == False :		
                    print >>f1, "<a href='"+file+"'>"+file+"</a><br/>"
