class DeviseAddLastseenable<%= table_name.camelize.singularize %> < ActiveRecord::Migration
  def self.up
    add_column :<%= table_name %>, :active, :boolean, default: true
    add_column :<%= table_name %>, :billed_at, :datetime
    add_column :<%= table_name %>, :activated_at, :datetime
    add_column :<%= table_name %>, :deactivated_at, :datetime
    add_column :<%= table_name %>, :rollover_active_duration, :int
    table_name.classify.find_each do |user|
      user.update_attribute(:activated_at, user.created_at)
    end
  end
  
  def self.down
    remove_column :<%= table_name %>, :active, :boolean
    remove_column :<%= table_name %>, :billed_at, :datetime
    remove_column :<%= table_name %>, :activated_at, :datetime
    remove_column :<%= table_name %>, :deactivated_at, :datetime
    remove_column :<%= table_name %>, :rollover_active_duration, :int
  end
end

