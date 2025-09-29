require "application_system_test_case"

class McpsTest < ApplicationSystemTestCase
  setup do
    @mcp = mcps(:one)
  end

  test "visiting the index" do
    visit mcps_url
    assert_selector "h1", text: "Mcps"
  end

  test "should create mcp" do
    visit mcps_url
    click_on "New mcp"

    click_on "Create Mcp"

    assert_text "Mcp was successfully created"
    click_on "Back"
  end

  test "should update Mcp" do
    visit mcp_url(@mcp)
    click_on "Edit this mcp", match: :first

    click_on "Update Mcp"

    assert_text "Mcp was successfully updated"
    click_on "Back"
  end

  test "should destroy Mcp" do
    visit mcp_url(@mcp)
    click_on "Destroy this mcp", match: :first

    assert_text "Mcp was successfully destroyed"
  end
end
