ArchivesSpace::Application.routes.draw do
  resources :transfer_proposals
  resources :transfers
  resources :transfer_files

  match 'transfers/approve' => 'transfers#approve', :via => [:post]
end
