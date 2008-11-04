
def callback(e)
 yield e
end

callback(nil) do |e|; end
