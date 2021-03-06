module TemplateRelation
  def self.included(base)
    base.extend ClassMethods
  end
  
  module ClassMethods
    
    def template_relation(relation_name, opts = {}, &block)
      options = {
        :foreign_key => nil,
        :number => nil, 
        :order_attribute => :position,
        :ordering => "ASC",
        :auto_save => true }.update(opts)

      order = options[:order_attribute].blank? ? nil : "#{options[:order_attribute]} #{options[:ordering]}"
      has_many relation_name, :order => order, :foreign_key => options[:foreign_key]

      validates_template_relation relation_name, options
      
      if options[:auto_save]
        after_save do |record|
          record.send(relation_name).each{|item| item.save }
        end
      end
      
      define_template_relation_setters_and_getters(relation_name, options)
    end
    
    def validates_template_relation(relation_name, options)
      validate_on_update do |record|
        record.errors.add(relation_name, "must have exactly #{options[:number]} records; current size is #{record.send(relation_name).size}") unless record.send(relation_name).size == options[:number]
      end
    end
    
    def define_template_relation_setters_and_getters(relation_name, options)
      options[:number].times do |i|
        # getter
        define_method "#{relation_name.to_s.singularize}_#{i+1}" do
          send(relation_name)[i]
        end
        
        # setter
        define_method "#{relation_name.to_s.singularize}_#{i+1}=" do |obj|
          if obj.is_a? ActiveRecord::Base
            if !send(relation_name)[i].blank?
              send(relation_name)[i].destroy unless send(relation_name)[i] == obj
            end
            send(relation_name)[i] = obj
          elsif obj.is_a? Hash
            send(relation_name)[i].attributes = obj
          else
          end
        end
      end
    end
    
  end
end

class ActiveRecord::Base
  include TemplateRelation
end