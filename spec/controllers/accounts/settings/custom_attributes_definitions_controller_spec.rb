require 'rails_helper'

RSpec.describe Accounts::Settings::CustomAttributesDefinitionsController, type: :request do
  let!(:account) { create(:account) }
  let!(:user) { create(:user, account: account) }
  let!(:another_account) { create(:account) }
  let(:custom_attribute_definition) { create(:custom_attribute_definition, :contact_attribute, account: account) }
  let(:custom_attribute_definition_first) { CustomAttributeDefinition.first }

  describe 'POST /accounts/{account.id}/custom_attributes_definitions' do
    let(:valid_params) do
      { custom_attribute_definition: { 'attribute_model' => 'contact_attribute', 'attribute_key' => 'cpf',
                                       'attribute_display_name' => 'CPF', 'attribute_description' => 'Cpf field' } }
    end

    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        post "/accounts/#{account.id}/custom_attributes_definitions"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      context 'create custom attribute definition' do
        it do
          expect do
            post "/accounts/#{account.id}/custom_attributes_definitions",
                 params: valid_params
          end.to change(CustomAttributeDefinition, :count).by(1)
          expect(response).to redirect_to(account_custom_attributes_definitions_path(account))
        end
        context 'when attribute_key is invalid' do
          it 'when attribute_key is blank' do
            invalid_params = { custom_attribute_definition: { 'attribute_model' => 'contact_attribute',
                                                              'attribute_key' => '', 'attribute_display_name' => 'CPF', 'attribute_description' => 'Cpf field' } }
            expect do
              post "/accounts/#{account.id}/custom_attributes_definitions",
                   params: invalid_params
            end.to change(CustomAttributeDefinition, :count).by(0)
            expect(response.body).to include('Chave não pode ficar em branco')
            expect(response).to have_http_status(:unprocessable_entity)
          end
          context 'when attribute_key already exists in currently account' do
            let!(:custom_attribute_definition) do
              create(:custom_attribute_definition, :contact_attribute, account: account)
            end
            it 'should not create' do
              params = { custom_attribute_definition: { 'attribute_model' => 'contact_attribute', 'attribute_key' => 'cpf',
                                                        'attribute_display_name' => 'CPF', 'attribute_description' => 'Cpf field' } }
              expect do
                post "/accounts/#{account.id}/custom_attributes_definitions",
                     params: params
              end.to change(CustomAttributeDefinition, :count).by(0)
              expect(response.body).to include('Chave já está em uso')
              expect(response).to have_http_status(:unprocessable_entity)
            end
            context 'when attribute_key already exists with contact_attribute, but not with deal_attribute' do
              it 'should create custom_attributte_definition' do
                params = { custom_attribute_definition: { 'attribute_model' => 'deal_attribute', 'attribute_key' => 'cpf',
                                                          'attribute_display_name' => 'CPF', 'attribute_description' => 'Cpf field' } }
                expect do
                  post "/accounts/#{account.id}/custom_attributes_definitions",
                       params: params
                end.to change(CustomAttributeDefinition, :count).by(1)
                expect(response).to redirect_to(account_custom_attributes_definitions_path(account))
              end
            end
          end
        end
        context 'when attribute_key already exists in another account' do
          let!(:custom_attribute_definition_another_account) do
            create(:custom_attribute_definition, :contact_attribute, account: another_account)
          end
          it 'should create custom_attributes_definitions' do
            expect do
              post "/accounts/#{account.id}/custom_attributes_definitions",
                   params: valid_params
            end.to change(CustomAttributeDefinition, :count).by(1)
            expect(response).to redirect_to(account_custom_attributes_definitions_path(account))
          end
        end
      end
    end
  end
  describe 'GET /accounts/{account_id}/custom_attributes_definitions/new' do
    context 'when is unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/custom_attributes_definitions/new"
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    context 'when is authenticated user' do
      before do
        sign_in(user)
      end
      it 'should redirect to new custom_attributes_definitions page' do
        get "/accounts/#{account.id}/custom_attributes_definitions/new"
        expect(response).to have_http_status(200)
        expect(response.body).to include('Criar Atributo personalizado')
      end
    end
  end

  describe 'GET /accounts/{account.id}/custom_attributes_definitions' do
    let!(:custom_attribute_definition) { create(:custom_attribute_definition, :contact_attribute, account: account) }
    let!(:custom_attribute_definition_another_account) do
      create(:custom_attribute_definition, :contact_attribute, attribute_display_name: 'RG field', attribute_key: 'rg',
                                                               account: another_account)
    end
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        get "/accounts/#{account.id}/custom_attributes_definitions"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      context 'get custom_attribute_definitions' do
        it 'should return only custom_attribute_deffinitions in currently account' do
          get "/accounts/#{account.id}/custom_attributes_definitions"
          expect(response.body).to include('CPF field')
          expect(response.body).not_to include('RG field')
          expect(response).to have_http_status(200)
        end
      end
    end
  end

  describe 'PATCH /accounts/{account.id}/custom_attributes_definitions/{custom_attribute_definition.id}' do
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        patch "/accounts/#{account.id}/custom_attributes_definitions/#{custom_attribute_definition.id}"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      context 'update custom_attribute_definition' do
        let(:valid_params) { { custom_attribute_definition: { attribute_display_name: 'CPF field updated' } } }
        it do
          patch "/accounts/#{account.id}/custom_attributes_definitions/#{custom_attribute_definition.id}",
                params: valid_params
          expect(custom_attribute_definition.reload.attribute_display_name).to eq(valid_params[:custom_attribute_definition][:attribute_display_name])
          expect(response.body).to redirect_to(edit_account_custom_attributes_definition_path(account,
                                                                                              custom_attribute_definition))
        end
      end
      context 'when updating attribute_key to an existing attribute_key' do
        let!(:another_custom_attribute_definition) do
          create(:custom_attribute_definition, :contact_attribute, attribute_display_name: 'RG field', attribute_key: 'rg',
                                                                   account: account)
        end
        invalid_params = { custom_attribute_definition: { 'attribute_key' => 'rg' } }
        it 'should not update' do
          patch "/accounts/#{account.id}/custom_attributes_definitions/#{custom_attribute_definition.id}",
                params: invalid_params
          expect(response.body).to include('Chave já está em uso')
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe 'DELETE /accounts/{account.id}/custom_attributes_definitions/{custom_attribute_definition.id}' do
    let!(:custom_attribute_definition) { create(:custom_attribute_definition, :contact_attribute, account: account) }
    context 'when it is an unauthenticated user' do
      it 'returns unauthorized' do
        delete "/accounts/#{account.id}/custom_attributes_definitions/#{custom_attribute_definition.id}"
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when it is an authenticated user' do
      before do
        sign_in(user)
      end

      context 'delete custom_attribute_definiton' do
        it do
          expect do
            delete "/accounts/#{account.id}/custom_attributes_definitions/#{custom_attribute_definition.id}"
          end.to change(CustomAttributeDefinition, :count).by(-1)
          expect(response.status).to eq(204)
        end
      end
    end
  end
end
