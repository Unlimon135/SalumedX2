# Interface abstracta para LLM Providers (Strategy Pattern)
class LLMAdapter
  def generate_response(prompt)
    raise NotImplementedError, "#{self.class} debe implementar #generate_response"
  end

  def generate_with_tools(prompt, tools)
    raise NotImplementedError, "#{self.class} debe implementar #generate_with_tools"
  end

  def stream_response(prompt)
    raise NotImplementedError, "#{self.class} debe implementar #stream_response"
  end
end
