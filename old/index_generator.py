import sys,os
f1=open('./note.html', 'w+')
print >>f1,""

for path, subdirs, files in os.walk("."):
	tmp = ""
	for name in files:
		file = os.path.join(path, name)
		if file.startswith('./.git') == False and file.startswith('./index') == False :
			if tmp != path :
				tmp = path
				print >>f1, "<h3>"+path+"</h3>"
			print >>f1, "<a href='"+file+"'>"+name+"</a><br/>"
