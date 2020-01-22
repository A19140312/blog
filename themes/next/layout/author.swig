{% extends '_layout.swig' %}
{% import '_macro/post-collapse.swig' as post_template %}
{% import '_macro/sidebar.swig' as sidebar_template %}

{% block title %} {{ __('title.author') }}: {{ page.author }} | {{ config.title }} {% endblock %}

{% block content %}

  <div class="post-block category">

    <div id="posts" class="posts-collapse">
      <div class="collection-title">

        <{% if theme.seo %}h2{% else %}h1{% endif %}>{#
        #}{{ page.author }}{#
        #}<small>{{  __('title.author')  }}</small>
        </{% if theme.seo %}h2{% else %}h1{% endif %}>
      </div>

      {% for post in page.posts %}
        {{ post_template.render(post) }}
      {% endfor %}
    </div>

  </div>

  {% include '_partials/pagination.swig' %}

{% endblock %}

{% block sidebar %}
  {{ sidebar_template.render(false) }}
{% endblock %}
