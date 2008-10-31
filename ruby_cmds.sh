
#Figure out some way to execute this properly:

ruby -Ilib -Itest /usr/bin/spec test/redsun_spec.rb

mspec -Ilib -Itest test/redsun_spec.rb

ruby -Ilib -Itest -Iresearch -rex -e 'RedSun::ABC::ABCFile.pp_yarv(@sc)'

ruby -Ilib -Itest -Iresearch -rex -e 'RedSun::ABC::ABCFile.yarv_to_as3(@sc)'

ruby -Ilib -Itest -Iresearch -rex -e 'RedSun::ABC::ABCFile.yarv_to_as3(bc("research/asterism.rb"))'

ruby -Ilib -Itest -Iresearch -rex -e 'puts RedSun::ABC::ABCFile.yarv_to_string(@sc).inspect'

irb -Ilib -Itest -Iresearch -rex

