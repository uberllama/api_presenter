module PresentableHelper
  def expect_present(relation_or_record)
    expect(presenter_klass).to have_received(:call).with(
      current_user: current_user,
      relation:     relation_or_record,
      params:       controller.params
    )
  end
end
