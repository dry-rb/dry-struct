RSpec.describe Dry::Struct, method: '.attribute' do
  let(:user_type) { Test::User }

  before do
    module Test
      class Role < Dry::Struct
        attribute :id, 'strict.integer'
        attribute :name, 'strict.string'
      end

      class User < Dry::Struct
      end
    end
  end

  context 'when given a block-style nested type' do
    context 'when the nested type is not already defined' do
      context 'with no superclass type' do
        before do
          module Test
            User.attribute(:permissions, Dry::Types['strict.array']) do
              attribute :id, 'strict.integer'
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
        %w(array strict.array coercible.array).each do |array_type|
          context "using #{ array_type }" do
            before do
              module Test
                class BasePermission < Dry::Struct
                  attribute :id, 'strict.integer'
                end
              end

              Test::User.attribute(:permissions, Dry::Types[array_type].of(Test:: BasePermission)) do
                attribute :name, 'strict.string'
              end
            end

            it 'uses the given array type' do
              expect(user_type.schema[:permissions]).
                to eql(Dry::Types[array_type].of(Test::User::Permission))
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
      end

      context 'with a named type' do
        before do
          module Test
            User.attribute(:permissions, 'strict.array') do
              attribute :id, 'strict.integer'
              attribute :name, 'strict.string'
            end
          end
        end

        it 'uses the given array type' do
          expect(user_type.schema[:permissions]).
            to eql(Dry::Types['strict.array'].of(Test::User::Permission))
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
          Test::User.attribute(:roles, Dry::Types['strict.array']) {}
        }.to raise_error(Dry::Struct::Error)
      end
    end
  end


  context 'when no nested attribute block given' do
    it 'raises error when type is missing' do
      expect {
        class Test::Foo < Dry::Struct
          attribute :bar
        end
      }.to raise_error(ArgumentError)
    end
  end
end
