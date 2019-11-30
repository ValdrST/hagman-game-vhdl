build:
	ghdl -a *.vhd 
	ghdl -e proyecto_final
	ghdl -r proyecto_final --vcd=proyecto_final.vcd

clean:
	rm *.o
	rm *.cf
	rm *.vcd