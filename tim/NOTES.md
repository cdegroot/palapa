Scribblenotes.... 


Running rtl_433 under Porcelain doesn't really fly. Ports seem to work fine:

	iex(1)> port = Port.open({:spawn, "rtl_433 -R 73 2>/dev/null"}, [])
	#Port<0.4977>
	iex(2)> Port.monitor(port)
	#Reference<0.4290375393.4011851779.254869>

kill -9 will send the expected DOWN message:

	iex(7)> flush
	{#Port<0.4977>, {:data, ' '}}
	{#Port<0.4977>,
	 {:data, '2018-01-24 03:16:49\n:\tLaCrosse TX141-Bv2 sensor\n\tSensor ID:\t '}}
	{#Port<0.4977>, {:data, 'a0'}}
	{#Port<0.4977>, {:data, '\n'}}
	{#Port<0.4977>, {:data, '\tTemperature:\t'}}
	{#Port<0.4977>, {:data, ' '}}
	{#Port<0.4977>, {:data, '-7.80 C'}}
	{#Port<0.4977>, {:data, '\n'}}
	{#Port<0.4977>, {:data, '\tBattery:\t'}}
	{#Port<0.4977>, {:data, ' '}}
	{#Port<0.4977>, {:data, 'OK'}}
	{#Port<0.4977>, {:data, '\n'}}
	{#Port<0.4977>, {:data, '\tTest?:\t'}}
	{#Port<0.4977>, {:data, ' '}}
	{#Port<0.4977>, {:data, 'No'}}
	{#Port<0.4977>, {:data, '\n'}}
	{#Port<0.4977>,
	 {:data,
	  ' 2018-01-24 03:16:55\n:\tLaCrosse TX141-Bv2 sensor\n\tSensor ID:\t 19\n\tTemperature:\t 2.40 C\n\tBattery:\t OK\n\tTest?:\t No\n'}}
	:ok
	iex(8)> flush
	{:DOWN, #Reference<0.4290375393.4011851779.254869>, :port, #Port<0.4977>,
	 :normal}
	:ok

and killing the VM will get rtl_433 reaped by init. Good both ways.

