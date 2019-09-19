require File.expand_path('../../test_helper', __FILE__)

class ProjectCustomFieldTest < ActiveSupport::TestCase
  fixtures :projects 
  fixtures :custom_fields
  
  def setup
    @project = Project.first
    @custom_field = ProjectCustomField.new(:name => 'custom_field', :field_format => 'float', :project => @project)
  end
  
  def test_save
    assert_difference ['ProjectCustomField.count', 'ProjectSpecificCustomFieldsProject.count'] do
      assert @custom_field.save
    end
    @custom_field.reload
    assert_equal 'custom_field', @custom_field.name
    assert_equal 'float', @custom_field.field_format
    assert_equal :label_project_specific_project_custom_field_plural, @custom_field.type_name
    assert_equal @custom_field, @project.project_specific_project_custom_fields.first
    assert ProjectCustomField.last.share_with_subprojects?
  end
  
  def test_save_set_share_with_subprojects_to_false
    @custom_field.share_with_subprojects = false
    assert @custom_field.save
    assert !ProjectCustomField.last.share_with_subprojects?
  end
  
  def test_duplicate
    assert @custom_field.save
    new_field = ProjectCustomField.new(:name => 'custom_field', :field_format => 'float', :project => @project)
    assert !new_field.save
  end
  
  def test_duplicate_of_global_field
    @custom_field.name = ProjectCustomField.first.name
    @custom_field.field_format=ProjectCustomField.first.field_format
    assert !@custom_field.save
  end
  
  def test_duplicate_on_different_project
    assert @custom_field.save
    new_project = Project.find(2)
    new_field = ProjectCustomField.new(:name => 'custom_field', :field_format => 'float', :project => new_project)
    assert new_field.save
  end
  
  def test_duplicate_of_different_field_format
    assert @custom_field.save
    new_field = ProjectCustomField.new(:name => 'custom_field', :field_format => 'string', :project => @project)
    assert new_field.save
  end
  
  def test_no_project
    @custom_field.project = nil
    assert !@custom_field.save
  end
  
  def test_load_and_save
    assert @custom_field.save
    field = ProjectCustomField.where(:id => @custom_field.id).first
    assert_equal @project, field.project
    assert_difference ['ProjectCustomField.count', 'ProjectSpecificCustomFieldsProject.count'], 0 do
      assert field.save
    end
  end
  
end
