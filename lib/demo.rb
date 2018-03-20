class Cat < SQLObject
  belongs_to :owner,
    class_name: "Human",
    foreign_key: :owner_id

  has_one_through :home, :owner, :house

  finalize!
end

class Human < SQLObject
  has_many :cats,
    class_name: "Cat",
    foreign_key: :owner_id,
    primary_key: :id

  belongs_to :house,
    class_name: "House",
    foreign_key: :house_id

  finalize!
end

class House < SQLObject
  has_many :humans,
    class_name: "Human",
    foreign_key: :house_id

  has_many_through :cats, :humans, :cats

  finalize!
end
