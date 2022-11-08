from django.apps import AppConfig


class UsersConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "users"

    def ready(self):
        """
        Signal Receiver:
            implicit connection to Handler's via decorator receiver
        """
        import users.signals
