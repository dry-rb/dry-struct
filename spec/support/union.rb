# frozen_string_literal: true

require "dry/struct/union"

module Union
  module Reopen
    module Type
      include Dry::Struct::Union
    end

    module Type
      class InnerA < Dry::Struct
        attribute :id, "integer"
      end
    end

    module Type
      class InnerB < Dry::Struct
        attribute :id, "string"
      end
    end
  end

  module Example
    class Base < Dry::Struct
      abstract
      schema schema.strict
    end

    module Types
      include Dry::Types()
    end

    module Weather
      include Dry::Struct.Union(include: [:Warm])
      MAX_TEMP = 274

      class Base < Example::Base
        abstract
        attribute :temp, "integer"
      end

      class Cold < Base
        attribute :id, Types.Value(:cold)
      end

      class Warm < Base
        attribute :id, Types.Value(:warm)
      end
    end

    module Season
      include Dry::Struct::Union

      class Spring < Example::Base
        attribute :id, Types.Value(:spring)
      end

      module Unused
        class Autum < Example::Base
          attribute :id, Types.Value(:autum)
        end
      end
    end

    module Planet
      include Dry::Struct.Union(exclude: :Pluto)

      class Base < Example::Base
        abstract
        attribute? :closest, Planet
        attribute? :season, Season
        attribute? :weather, Weather
      end

      class Pluto < Base
        attribute :id, Types.Value(:pluto)
      end

      class Earth < Base
        attribute :id, Types.Value(:earth)
      end

      class Mars < Base
        attribute :id, Types.Value(:mars)
      end
    end
  end
end
