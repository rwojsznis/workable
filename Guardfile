directories %w(lib spec)

guard :rspec, cmd: "rspec" do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch(%r{spec/(spec_helper|fixtures)\.rb$})  { "spec" }
end
