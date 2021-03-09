include .env

install:
	docker-compose exec -T php ../vendor/bin/drush site-install idea \
		--local=en \
		--account-name=$(ACCOUNT_NAME) \
		--account-mail=$(ACCOUNT_EMAIL) \
		--account-pass=$(ACCOUNT_PASSWORD) \
		--db-url=mysql://$(DB_USER):$(DB_PASSWORD)@$(DB_HOST):3306/$(DB_NAME) \
		--site-name="$(SITE_NAME)" \
		install_configure_form.update_status_module='array(FALSE,FALSE)' \
		-y
