import sys

input_file_name  = sys.argv[1]
output_file_name = sys.argv[2]

rf = open(input_file_name, 'r')
input_lines = rf.readlines()
rf.close()

output_lines = []

for iline in input_lines:
    oline = ""
    if (iline[0]=='@'):
        #load hex value and divde by 4
        oline = "@" + "{:x}".format(int(int(iline[1:], 16)/4)).rjust(8, '0') + "\n"
    else:
        items = iline.split()
        for i in range(int(len(items)/4)):
            oline = oline + items[i*4+3] + items[i*4+2] + items[i*4+1] + items[i*4] + " "
        oline = oline[:-1] + "\n"
    output_lines.append(oline)
wf = open(output_file_name, 'w')
wf.writelines(output_lines)
wf.close()

