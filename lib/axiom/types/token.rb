class Axiom::Types::Token < Axiom::Types::String
  def self.infer(object)
    if object == Axiom::Types::Token
      self
    end
  end
end
