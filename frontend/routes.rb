ArchivesSpace::Application.routes.draw do
  match 'transfer_files/validate' => 'transfer_files#validate', :via => [:get]

  match 'transfer_proposals/approve' => 'transfer_proposals#approve', :via => [:post]
  match 'transfer_proposals/cancel' => 'transfer_proposals#cancel', :via => [:post]
  match 'transfers/:id' => 'transfers#update', :via => [:post]
  match 'transfer_file/replace' => 'transfers#replace_file', :via => [:post]
  match 'transfers/:id/import' => 'transfers#import', :via => [:post]

  match 'transfer_conversation' => 'transfers#conversation', :via => [:get]
  match 'transfer_conversation_send' => 'transfers#conversation_send', :via => [:post]

  match 'file_issue_requests/:id' => 'file_issue_requests#update', :via => [:post]

  resources :transfer_proposals
  resources :transfers
  resources :transfer_files
  resources :file_issue_requests
end
