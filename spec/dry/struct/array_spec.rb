RSpec.describe Dry::Struct, method: '.array' do
  let(:user_type) { Test::User }

  before do
    module Test
      class Role < Dry::Struct
        attribute :id, 'strict.int'
        attribute :name, 'strict.string'
      end

      class User < Dry::Struct
      end
    end
  end

  context 'when given a pre-defined nested type' do
    before do
      Test::User.array(:roles, Test::Role)
    end

    it 'defines attributes for the constructor' do
      user = user_type[
        roles: [{ id: 1, name: 'root' }, { id: 2, name: 'admin' }]
      ]

      expect(user.roles.length).to be(2)
      expect(user.roles[0].id).to be(1)
      expect(user.roles[0].name).to eql('root')
      expect(user.roles[1].id).to be(2)
      expect(user.roles[1].name).to eql('admin')
    end
  end

  context 'when given a block-style nested type' do
    context 'when the nested type is not already defined' do
      context 'with no superclass type' do
        before do
          module Test
            User.array(:permissions) do
              attribute :id, 'strict.int'
              attribute :name, 'strict.string'
            end
          end
        end

        it 'defines attributes for the constructor' do
          user = user_type[
            permissions: [{ id: 1, name: 'all' }, { id: 2, name: 'edit_users' }]
          ]

          expect(user.permissions.length).to be(2)
          expect(user.permissions[0].id).to be(1)
          expect(user.permissions[0].name).to eql('all')
          expect(user.permissions[1].id).to be(2)
          expect(user.permissions[1].name).to eql('edit_users')
        end

        it 'defines a nested type' do
          expect { user_type.const_get('Permission') }.to_not raise_error
        end
      end

      context 'with a superclass type' do
        before do
          module Test
            class BasePermission < Dry::Struct
              attribute :id, 'strict.int'
            end

            User.array(:permissions, BasePermission) do
              attribute :name, 'strict.string'
            end
          end
        end

        it 'defines attributes for the constructor' do
          user = user_type[
            permissions: [{ id: 1, name: 'all' }, { id: 2, name: 'edit_users' }]
          ]

          expect(user.permissions.length).to be(2)
          expect(user.permissions[0].id).to be(1)
          expect(user.permissions[0].name).to eql('all')
          expect(user.permissions[1].id).to be(2)
          expect(user.permissions[1].name).to eql('edit_users')
        end

        it 'defines a nested type' do
          expect { user_type.const_get('Permission') }.to_not raise_error
        end
      end
    end

    context 'when the nested type is already defined' do
      before do
        module Test
          class User < Dry::Struct
            class Role < Dry::Struct
            end
          end
        end
      end

      it 'raises a Dry::Struct::Error' do
        expect {
          Test::User.array(:roles) {}
        }.to raise_error(Dry::Struct::Error)
      end
    end
  end


  context 'when no nested attribute block given' do
    it 'raises error when type is missing' do
      expect {
        class Test::Foo < Dry::Struct
          array :bar
        end
      }.to raise_error(ArgumentError)
    end
  end

  context 'when nested attribute block given' do
    it 'does not raise error when type is missing' do
      expect {
        class Test::Foo < Dry::Struct
          array :bars do
            attribute :foo, 'strict.string'
          end
        end
      }.to_not raise_error
    end
  end

  it 'raises error when attribute is defined twice' do
    expect {
      class Test::Foo < Dry::Struct
        array :bars, 'strict.string'
        array :bars, 'strict.string'
      end
    }.to raise_error(
      Dry::Struct::RepeatedAttributeError,
      'Attribute :bars has already been defined'
    )
  end

  it 'allows to redefine attributes in a subclass' do
    expect {
      class Test::Foo < Dry::Struct
        array :bars, 'strict.string'
      end

      class Test::Bar < Test::Foo
        array :bars, 'strict.int'
      end
    }.not_to raise_error
  end

  it 'can be chained' do
    class Test::Foo < Dry::Struct
    end

    Test::Foo
      .array(:foos, 'strict.string')
      .array(:bars, 'strict.int')

    foo = Test::Foo.new(foos: ['foo'], bars: [123])

    expect(foo.foos).to eql(['foo'])
    expect(foo.bars).to eql([123])
  end

  it "doesn't define readers if methods are present" do
    class Test::Foo < Dry::Struct
      def foos
        @foos.length
      end
    end

    Test::Foo
      .array(:foos, 'strict.string')

    struct = Test::Foo.new(foos: ['bar', 'baz'])
    expect(struct.foos).to be(2)
  end
end
