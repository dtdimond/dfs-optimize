RSpec::Matchers.define :be_near_to_time do |another_date, delta=0|
  match do |a_date|
    expect(a_date.to_i).to be_within(delta.to_i).of(another_date.to_i)
  end
end
