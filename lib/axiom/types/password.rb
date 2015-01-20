class Axiom::Types::Password < Axiom::Types::String
  def self.infer(object)
    if object == Axiom::Types::Password
      self
    end
  end
end
