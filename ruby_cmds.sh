
#Figure out some way to execute this properly:

ruby -Ilib -Itest /usr/bin/spec test/redsun_spec.rb

ruby -Ilib -Itest -Iresearch -rex -e 'RedSun::ABC::ABCFile.pp_yarv(@sc)'

