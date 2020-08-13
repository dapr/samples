using System;
using System.Threading.Tasks;
using System.Text.Json;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Dapr.Client;

namespace Provider
{
    public class Startup
    {
        public const string stateStore = "statestore";
        
        public Startup(IConfiguration configuration)
        {
            Configuration = configuration;
        }

        public IConfiguration Configuration { get; }

        // This method gets called by the runtime. Use this method to add services to the container.
        public void ConfigureServices(IServiceCollection services)
        {
            services.AddDaprClient();
            services.AddSingleton(new JsonSerializerOptions()
            {
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
                PropertyNameCaseInsensitive = true,
            });
        
        }

        // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
        public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
        {
            if (env.IsDevelopment())
            {
                app.UseDeveloperExceptionPage();
            }

            app.UseRouting();

            app.UseEndpoints(endpoints =>
            {
                endpoints.MapPost("tweet", Tweet);
            });

            async Task Tweet (HttpContext context)
            {                
                var client = context.RequestServices.GetRequiredService<DaprClient>();
                var requestBodyStream = context.Request.Body;

                var tweet = await JsonSerializer.DeserializeAsync<TwitterTweet>(requestBodyStream);
                Console.WriteLine("Tweet received: {0}: {1}", tweet.ID, tweet.Text);
    
                await client.SaveStateAsync<TwitterTweet>(stateStore, tweet.ID, tweet);
                Console.WriteLine("Tweet saved: {0}: {1}", tweet.ID, tweet);
                
                return;
            }
        }
    }
}
