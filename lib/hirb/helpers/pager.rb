class Hirb::Helpers::Pager
  def self.render(obj, options={})
    @pager = setup_pager
    begin
      save_stdout = STDOUT.clone
      STDOUT.reopen(@pager)    
      puts obj
    ensure
     STDOUT.reopen(save_stdout)
     save_stdout.close
     @pager.close
    end
  end

  def self.setup_pager
    IO.popen(pager_binary, "w")
  end

  def self.has_valid_pager?
    !! pager_binary
  end

  def self.pager_binary
    @pager_binary ||= [ ENV['PAGER'], 'pager', 'less', 'more'].compact.uniq.find {|e|
      ENV['PATH'].split(File::PATH_SEPARATOR).any? {|d| File.exists? File.join(d, e) }
    }
  end
end