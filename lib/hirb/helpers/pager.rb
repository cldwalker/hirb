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
    for pager in [ ENV['PAGER'], "less", "more", 'pager' ].compact.uniq
      return IO.popen(pager, "w") rescue nil
    end
  end
end