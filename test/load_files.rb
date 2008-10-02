
module TestFiles
  Dir.chdir(File.dirname(__FILE__)) do
    Dir['files/*.{swf,xhtml,xml}'].each do |fname|
      puts "got name - #{fname}"
      barename = fname[%r!/([\w.]+)\.\w+$!, 1]
      barename = barename[0].upcase << barename[1..-1]
      const_set barename, IO.read(fname)
    end
  end
end
