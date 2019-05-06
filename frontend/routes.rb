ArchivesSpace::Application.routes.draw do
  resources :transfer_proposals
  resources :transfers
  resources :transfer_files

  match 'transfers/approve' => 'transfers#approve', :via => [:post]
  match 'transfer_conversation' => 'transfers#conversation', :via => [:get]
  match 'transfer_conversation_send' => 'transfers#conversation_send', :via => [:post]
end
