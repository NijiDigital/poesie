class String

  def poeditor
    self.gsub('\\\\n', '\\n').gsub(/%(\d\$)?s/, '%\1@')
  end

  def camel_case
    self.split('_')
        .map { |s| s.gsub('"', '').capitalize }
        .join
  end

  def fake_escape
    self.gsub('&', '&amp;')
  end

end
