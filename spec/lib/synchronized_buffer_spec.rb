require File.dirname(__FILE__) + '/../spec_helper'

describe SynchronizedBuffer do

  describe "Capacity" do

    it "should should require a capacity greater than zero" do
      lambda { SynchronizedBuffer.new(-1) }.should raise_error(ArgumentError)
      lambda { SynchronizedBuffer.new(0) }.should raise_error(ArgumentError)
    end

  end

  describe "Get" do

    before do
      @buffer = SynchronizedBuffer.new(5)
      @buffer.put(Object.new)
    end

    it "should return an object (or wait if empty) when invoking get" do
      obj = @buffer.get
      obj.should_not be_nil
    end
  end

end
