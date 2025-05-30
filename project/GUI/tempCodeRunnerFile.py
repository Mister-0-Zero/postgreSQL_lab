                        ft.Markdown(
                            readme_text,
                            selectable=True,
                            extension_set=ft.MarkdownExtensionSet.GITHUB_WEB,
                            code_theme="atom-one-dark",
                            on_tap_link=lambda e: page.launch_url(e.data),
                            style=md_style,
                            expand=True,
                        )